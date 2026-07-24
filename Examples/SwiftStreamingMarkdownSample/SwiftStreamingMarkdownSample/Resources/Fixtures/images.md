# Images

Block-level image rendering is opt-in through the experimental `ImageConfig`.
This sample enables the asset-catalog, bundled-resource, and remote-allowlist
source types. Tap any image to open the built-in fullscreen viewer.

## Asset-catalog image

Loaded by name from the app's asset catalog via an `assets://` source.

![Mountain lake landscape](assets://Images/mountain-lake)

## Bundled resource image

Loaded from a loose file in the app bundle via a scheme-less relative path.

![Coastal sunset over the sea](coastal-sunset.png)

## Remote image

Loaded over `https` from an allowlisted host, shown with a shimmer placeholder
while it downloads.

![Mountains](https://www.markdownguide.org/assets/images/generated/assets/images/san-juan-mountains-1080.webp)

## Images alongside text

An image embedded in a paragraph is split out into its own block, so the
surrounding text keeps flowing. Before the image ![Mountain lake
landscape](assets://Images/mountain-lake) and after the image the paragraph
continues normally.

## Unresolved source

A source that matches no permitted type renders a placeholder instead of
breaking the layout.

![Blocked host](https://untrusted.example.com/photo.png)
