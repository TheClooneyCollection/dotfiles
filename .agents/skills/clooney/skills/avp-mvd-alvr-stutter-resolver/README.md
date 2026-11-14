# avp-mvd-alvr-stutter-resolver

Audits and fixes stutter when streaming to Apple Vision Pro with Mac Virtual Display (MVD) or ALVR.

The usual cause: Apple devices share one radio between your router's channel and AWDL, the peer-to-peer link MVD uses. When the two channels differ, the radio time-slices between them and the stream stutters. Picking a "clean" channel alone does not fix it.

**Why:** My Vision Pro stream stuttered for no obvious reason, and the cause was spread across Wi-Fi settings on the Mac, router and PC. This audits all of them and lists the fixes.

**Use it:** report MVD or ALVR stutter, lag or drops, ask which router channel or width to use for Vision Pro, or ask for your VR network to be checked.

## What it checks

1. The Mac's Wi-Fi channel, width and mode.
2. The AWDL channel sequence against the router channel.
3. Whether the Mac's traffic goes over Ethernet.
4. That the Mac, Vision Pro and gaming PC share one subnet.
5. That MVD traffic is flowing.
6. On the Windows ALVR PC: subnet, GPU encoder load, and whether Parsec is competing for the encoder.
7. Neighbouring networks, from a Wi-Fi scanner screenshot if the channel is in doubt.

It then reports each item as OK or as an issue with its fix, and asks you to retest the stream.

## The target setup, in short

A dedicated router near the play space, PC and Mac wired to it, Vision Pro on its Wi-Fi, one subnet. 5 GHz, 80 MHz, a non-DFS block (36-48 or 149-161), primary channel set to the AWDL channel (44 in the UK, often 149 elsewhere), 802.11ax enabled.

## Needs

macOS. Some commands need `sudo`; the agent gives you a line to paste in your own terminal and never asks for your password.

Agent instructions: [SKILL.md](SKILL.md).
