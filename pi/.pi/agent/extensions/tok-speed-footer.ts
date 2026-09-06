/**
 * Custom Footer — Real-time tok/s (tokens per second) with tiktoken
 *
 * 用 /footer 開關
 * Left:  model (thinking) • [42 tok/s] (~128 tok)
 * Right: [####.........] 40% (128K)
 *
 * 使用 tiktoken 精確計算 token 數。
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { get_encoding } from "tiktoken";

type RgbColor = { r: number; g: number; b: number };

// ── Tiktoken tokenizer (async init) ──

let tiktokenInstance: Awaited<ReturnType<typeof get_encoding>> | null = null;
let tiktokenReady = false;

async function initTiktoken(): Promise<boolean> {
    if (tiktokenReady) return true;
    try {
        tiktokenInstance = get_encoding("cl100k_base");
        tiktokenReady = true;
        return true;
    } catch {
        try {
            tiktokenInstance = get_encoding("p50k_base");
            tiktokenReady = true;
            return true;
        } catch {
            tiktokenInstance = null;
            return false;
        }
    }
}

function encodeWithFallback(text: string): number {
    if (!text) return 0;
    if (tiktokenInstance) {
        try {
            return tiktokenInstance.encode(text).length;
        } catch {
            return Math.round(text.length / 3.0);
        }
    }
    return Math.round(text.length / 3.0);
}

/** Count tokens from a plain text string (already extracted by countAllContentText). */
function countTextTokens(text: string): number {
    return encodeWithFallback(text);
}

process.on("exit", () => tiktokenInstance?.free());

// ── Helpers ──

function interpolateColor(t: number, stops: RgbColor[]): RgbColor {
    const clamped = Math.max(0, Math.min(1, t));
    const idx = clamped * (stops.length - 1);
    const i = Math.floor(idx);
    const f = idx - i;
    const a = stops[Math.min(i, stops.length - 1)]!;
    const b = stops[Math.min(i + 1, stops.length - 1)]!;
    return {
        r: Math.round(a.r + (b.r - a.r) * f),
        g: Math.round(a.g + (b.g - a.g) * f),
        b: Math.round(a.b + (b.b - a.b) * f),
    };
}

function colorRgb(text: string, c: RgbColor): string {
    return `\x1b[38;2;${c.r};${c.g};${c.b}m${text}\x1b[39m`;
}

function formatContextWindow(n: number | undefined): string {
    if (!n) return "";
    if (n >= 1_000_000) {
        const divisor = 1_000_000;
        const isExact = n % divisor === 0;
        return `${(n / divisor).toFixed(isExact ? 0 : 1)}M`;
    }
    if (n >= 1_000) {
        const divisor = 1_000;
        const isExact = n % divisor === 0;
        return `${(n / divisor).toFixed(isExact ? 0 : 1)}K`;
    }
    return `${n}`;
}

const TOKS_STOPS: RgbColor[] = [
    { r: 255, g: 69, b: 58 }, // red  - slow (<5 tok/s)
    { r: 255, g: 159, b: 10 }, // orange
    { r: 255, g: 214, b: 10 }, // yellow
    { r: 52, g: 199, b: 89 }, // green  - fast (>35 tok/s)
];

const CONTEXT_STOPS: RgbColor[] = [
    { r: 52, g: 199, b: 89 }, // green
    { r: 255, g: 214, b: 10 }, // yellow
    { r: 255, g: 159, b: 10 }, // orange
    { r: 255, g: 69, b: 58 }, // red
];

// Structural fields that appear in message parts but are NOT model content.
// These are skipped by the catch-all to avoid false token captures.
const STRUCTURAL_FIELDS = new Set([
    "type", // Block type (text, tool_use, thinking, etc.)
    "id", // Tool call ID
    "name", // Tool name
    "status", // Tool status
    "cache_control", // EBSI cache control
    "cachePriority", // Experimental cache priority
]);

// Known content fields handled by specific type checks.
// Prevents the catch-all from re-adding these.
const CONTENT_FIELDS = new Set(["text", "thinking", "message", "content"]);

const PROVIDER_COLORS: Record<string, RgbColor> = {
    anthropic: { r: 191, g: 90, b: 242 },
    openai: { r: 52, g: 199, b: 89 },
    google: { r: 66, g: 133, b: 244 },
    gemini: { r: 66, g: 133, b: 244 },
    github: { r: 175, g: 82, b: 222 },
    copilot: { r: 175, g: 82, b: 222 },
    openrouter: { r: 255, g: 159, b: 10 },
    ollama: { r: 142, g: 142, b: 147 },
    local: { r: 142, g: 142, b: 147 },
    vllm: { r: 142, g: 142, b: 147 },
};

// ── Footer state ──

let tuiRef: { requestRender(): void } | null = null;
let sessionCtxRef: any = null; // Captured session context

// Streaming stats
let isStreaming = false;
let streamingFullText = "";
let streamingRealTokens = 0;
let streamingStartTime = 0; // When generation starts (message_start)

function keepFresh(): void {
    tuiRef?.requestRender();
}

/**
 * Concatenate all content from message parts into one string.
 * Handles text, thinking, tool_use (input), file_write (content),
 * error (message), and any other string-valued fields.
 * This captures tokens from ALL content types the model streams.
 */
function countAllContentText(parts: any[]): string {
    let result = "";
    for (const p of parts) {
        if (p.type === "text" && typeof p.text === "string") {
            result += p.text;
        } else if (p.type === "thinking" && typeof p.thinking === "string") {
            result += p.thinking;
        } else if (
            p.type === "tool_use" &&
            typeof p.input === "object" &&
            p.input !== null
        ) {
            result += JSON.stringify(p.input);
        } else if (p.type === "file_write" && typeof p.content === "string") {
            result += p.content;
        } else if (p.type === "error" && typeof p.message === "string") {
            result += p.message;
        }

        // Catch-all: add any other string fields. Skip structural and content fields.
        for (const key of Object.keys(p)) {
            if (
                !STRUCTURAL_FIELDS.has(key) &&
                !CONTENT_FIELDS.has(key) &&
                typeof p[key] === "string"
            ) {
                result += p[key];
            }
        }
    }
    return result;
}

// Estimated ratio of actual output tokens vs captured content tokens.
// Helps estimate total during streaming when usage.output is not yet available.
let tokenEstimateHistory: number[] = [];
function getTokenEstimateRatio(): number {
    if (tokenEstimateHistory.length < 2) return 1.0;
    const avg =
        tokenEstimateHistory.reduce((a, b) => a + b, 0) /
        tokenEstimateHistory.length;
    return Math.max(1.0, avg);
}

// ── Extension entry ──

export default function (pi: ExtensionAPI) {
    // /footer command to toggle
    pi.registerCommand("footer", {
        description: "Toggle tok-speed footer",
        handler: async (_args, ctx) => {
            footerEnabled = !footerEnabled;
            if (footerEnabled) {
                ctx.ui.setFooter(makeFooter);
                ctx.ui.notify("Footer enabled", "info");
            } else {
                ctx.ui.setFooter(undefined);
                ctx.ui.notify("Footer disabled", "info");
            }
        },
    });

    pi.on("session_start", async (_event, ctx) => {
        sessionCtxRef = ctx;
        footerEnabled = true;

        ctx.ui.setFooter(makeFooter);

        // ── Streaming event handlers ──

        pi.on("message_start", async (event) => {
            if (event.message.role === "assistant") {
                streamingFullText = "";
                streamingRealTokens = 0;
                streamingStartTime = Date.now(); // Start timing from message_start (endpoint stream begins)
                isStreaming = true;
                keepFresh();
            }
        });

        pi.on("message_update", async (event) => {
            if (event.message.role === "assistant") {
                const parts = event.message.content || [];
                // Count ALL content blocks, not just text + thinking
                const full = countAllContentText(parts);
                if (full !== streamingFullText) {
                    streamingFullText = full;
                    keepFresh();
                }
            }
        });

        pi.on("message_end", async (event) => {
            if (event.message.role === "assistant") {
                const usage = (event.message as any).usage;
                if (usage?.output) {
                    streamingRealTokens = usage.output;

                    // Track ratio: actual output tokens / captured content tokens
                    // Captured content may miss some tokens (structural, whitespace, special tokens),
                    // so the ratio helps us estimate total during streaming.
                    const contentTokens = countTextTokens(streamingFullText);
                    if (contentTokens > 0 && usage.output > contentTokens) {
                        tokenEstimateHistory.push(usage.output / contentTokens);
                        // Keep last 10 samples
                        if (tokenEstimateHistory.length > 10)
                            tokenEstimateHistory.shift();
                    }
                }
                keepFresh();
            }
        });

        pi.on("turn_end", async () => {
            isStreaming = false;
            streamingFullText = "";
            streamingRealTokens = 0;
            streamingStartTime = 0;
            tokenEstimateHistory = [];
            keepFresh();
        });
    });
}

let footerEnabled = false;

// ── Footer factory ──

function makeFooter(tui: any, theme: any, footerData: any) {
    tuiRef = tui;

    return {
        dispose() {
            tuiRef = null;
        },
        invalidate() {
            tuiRef?.requestRender();
        },
        render(width: number): string[] {
            return renderFooter(sessionCtxRef, width, theme);
        },
    };
}

// ── Footer rendering (called every render cycle) ──

function renderFooter(ctx: any, width: number, theme: any): string[] {
    // Get model info
    const model = ctx?.model?.id || "unknown";
    const provider = (ctx?.model as any)?.provider || "";

    const providerColor = PROVIDER_COLORS[provider.toLowerCase()];
    const modelStr =
        provider && !model.includes("/")
            ? (providerColor ? colorRgb(provider, providerColor) : "") +
              theme.fg("dim", "/") +
              theme.fg("accent", model)
            : theme.fg("accent", model);

    // ── tok/s display ──
    let tokSpeedStr = "";

    // Calculate tok/s using elapsed time from message_start
    const elapsedSec =
        streamingStartTime > 0 ? (Date.now() - streamingStartTime) / 1000 : 0;

    let currentTokens: number;
    if (streamingRealTokens > 0) {
        // Final accurate count from usage
        currentTokens = streamingRealTokens;
    } else if (streamingFullText.length > 0) {
        // Estimate total tokens: captured content tokens * learned ratio
        const contentTokens = countTextTokens(streamingFullText);
        const ratio = getTokenEstimateRatio();
        currentTokens = Math.round(contentTokens * ratio);
    } else {
        currentTokens = 0;
    }

    let tokSpeed: number | undefined = undefined;

    if (isStreaming && streamingStartTime > 0 && elapsedSec > 0.1) {
        tokSpeed = currentTokens / elapsedSec;
        if (tokSpeed > 500) tokSpeed = undefined; // cap: treat as noise
    }

    if (tokSpeed !== undefined) {
        const rounded = Math.round(tokSpeed);
        const position = Math.min(1, Math.max(0, (tokSpeed - 5) / 35));
        const tokColor = interpolateColor(position, TOKS_STOPS);

        tokSpeedStr = colorRgb(`${rounded} tok/s`, tokColor);
    }

    const left = modelStr + (tokSpeedStr ? ` • ${tokSpeedStr}` : "");

    // ── Context bar ──
    const usage = ctx?.getContextUsage?.();
    const pct = usage?.percent ?? 0;

    const BLOCKS = 10;
    const filled = Math.max(
        0,
        Math.min(BLOCKS, Math.round((pct / 100) * BLOCKS)),
    );
    const bar =
        colorRgb(
            "#".repeat(filled),
            interpolateColor(pct / 100, CONTEXT_STOPS),
        ) + theme.fg("dim", ".".repeat(BLOCKS - filled));

    const pctStr = usage?.percent !== null ? `${Math.round(pct)}%` : "?";
    const ctxWin = formatContextWindow((ctx?.model as any)?.contextWindow);
    const ctxColor = interpolateColor(pct / 100, CONTEXT_STOPS);

    const right =
        colorRgb("[", ctxColor) +
        bar +
        colorRgb("] ", ctxColor) +
        colorRgb(pctStr, ctxColor) +
        (pct >= 75
            ? colorRgb(` (${ctxWin})`, ctxColor)
            : theme.fg("dim", ` (${ctxWin})`));

    // ── Layout ──
    const leftW = visibleWidth(left);
    const rightW = visibleWidth(right);

    if (leftW + rightW <= width) {
        const pad = " ".repeat(width - leftW - rightW);
        return [truncateToWidth(left + pad + right, width)];
    }

    // Two rows if too narrow
    return [truncateToWidth(left, width), truncateToWidth(right, width)];
}
