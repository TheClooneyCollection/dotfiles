---
name: catch-up
description: Brief the user on what changed since their last message, in a fixed shape. Use when the user says "catch me up", "cmu", "since my last message", "what happened", 发生了什么 or 进展.
---

# Catch up

Cover only what happened after the user's last message. Use these parts in order, omitting any part with no content:

1. **Landed:** what landed and the state now.
2. **Pending:** what is pending or blocked.
3. **Decision:** a decision the user must make, as one question with options.

Use one or two sentences per part. Concise means shape and density. Do not restate messages the user can read directly, such as a secondary's replies in a chain; do not narrate tool calls. No preamble or closing.

"What are you doing / why is it slow" is not a catch-up: answer that first in one or two sentences, then continue the work.
