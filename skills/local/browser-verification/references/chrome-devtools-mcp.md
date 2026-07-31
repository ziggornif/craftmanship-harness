# chrome-devtools MCP — tool recipes for browser verification

Tool-level detail for the `browser-verification` skill. The skill says *what* to verify; this says *how*, with the gotchas that cost a session to learn.

Standard server: **`chrome-devtools-mcp`** (official plugin — install with `/plugin`, tools appear as `mcp__plugin_chrome-devtools-mcp_chrome-devtools__*`). Fallback: `claude-in-chrome` covers navigate / screenshot / console / click but has **no Lighthouse and no viewport emulation**, so it cannot run the full matrix — use it only to keep going when the plugin is unavailable, and say so in the verdict.

## Tool map

| Need | Tool |
|---|---|
| open / go to a URL | `new_page`, `navigate_page`, `select_page`, `list_pages` |
| see the page structure (for element refs) | `take_snapshot` |
| capture evidence | `take_screenshot` |
| **measure anything** | `evaluate_script` |
| viewport / device / theme emulation | `emulate` |
| resize the real window | `resize_page` |
| interact | `click`, `hover`, `fill`, `fill_form`, `press_key`, `drag`, `upload_file` |
| wait for a state | `wait_for` |
| console | `list_console_messages`, `get_console_message` |
| network | `list_network_requests`, `get_network_request` |
| audit | `lighthouse_audit` |
| a blocking native dialog | `handle_dialog` |

## Gotchas that matter

- **Below ~500px, `resize_page` does not work.** macOS enforces a minimum window width, so a request for 390px silently lands wider and the mobile check is a lie. Use **`emulate` with a `viewport`** for the 390px (and any sub-500px) pass. Verify the width you actually got before trusting the pass: `window.innerWidth`.
- **Lighthouse is per theme.** Pass the `colorScheme` and use **snapshot** mode. A light-theme audit says nothing about the dark theme — that is exactly how a contrast failure ships.
- **Never trigger a native dialog.** `alert`, `confirm`, `prompt` and `beforeunload` block every subsequent MCP command; the session is dead until a human dismisses it in the browser. Avoid the buttons that raise them, and if one appears, `handle_dialog`. Use `console.log` + `list_console_messages` for anything you would have debugged with `alert`.
- **`take_snapshot` before interacting.** Element references come from the snapshot; clicking by guessed selector is how a verification run drifts into debugging the verifier.
- **Reload after a rebuild.** A preview server hands out hashed assets; the tab may still hold the previous build. Navigate again rather than assuming.

## Measurement snippets (`evaluate_script`)

Horizontal overflow — the single cheapest layout check:

```js
() => {
  const d = document.documentElement;
  return { scrollWidth: d.scrollWidth, clientWidth: d.clientWidth,
           overflow: d.scrollWidth > d.clientWidth,
           culprits: [...document.querySelectorAll('*')]
             .filter(e => e.getBoundingClientRect().right > d.clientWidth + 1)
             .slice(0, 10).map(e => e.tagName + '.' + e.className) };
}
```

Computed values against the design reference:

```js
() => {
  const s = getComputedStyle(document.querySelector('.card'));
  return { color: s.color, background: s.backgroundColor, fontSize: s.fontSize,
           padding: s.padding, gap: s.gap, radius: s.borderRadius };
}
```

Tap targets under 44px at mobile width:

```js
() => [...document.querySelectorAll('a,button,input,select,[role="button"]')]
  .map(e => ({ el: e.tagName + (e.textContent || '').trim().slice(0, 20),
               ...e.getBoundingClientRect().toJSON() }))
  .filter(r => r.width < 44 || r.height < 44);
```

Contrast — compute it, do not judge it by eye. Sample the element's computed color and its effective background, convert to relative luminance, and report the ratio against 4.5 (body) / 3.0 (large text). Run it **once per theme**.

Viewport sanity check after `emulate`:

```js
() => ({ width: window.innerWidth, dpr: devicePixelRatio,
         theme: matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light' })
```

## Comparing against reference screenshots

Full-page-vs-full-page comparison is unreliable at model resolution. Crop both to the region under test first:

```bash
sips -c <height> <width> --cropOffset <y> <x> reference.png --out region.png
```

Then compare the crop, and back the judgment with measured values from the live page — the crop shows *that* something differs, the measurement says *by how much*.

## Simulating drag & drop

File drop zones cannot be exercised through `click`. Dispatch synthetic events from `evaluate_script` — `dragenter`, `dragover`, then `drop` with a `DataTransfer` carrying a real `File` — to reach the "drag over", "uploading" and "rejected format" states. For the *real* upload path, use `upload_file` on the underlying `<input type="file">`.

## Checking claimed side effects

A UI that says "email sent" proves nothing. Check the destination: Mailpit for mail, the database for a row, the filesystem for an artifact. If the run recipe does not start that dependency, add it to `.harness/config.yml` under `run.deps` so the next verification does not rediscover it.
