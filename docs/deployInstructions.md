# Deploy instructions

This document is for my personal use only, so I don't forget anything ;)

## Preparation & checks
- [ ] Verify planned deprecations
- [ ] Fill changelog
- [ ] Update JSON changelog if necessary
- [ ] Rebuild all LDtk sample maps
- [ ] Update Haxe API sample maps
- [ ] Check JSON doc (changed/added flags etc.)
- [ ] Run Haxe API tests
- [ ] Build Haxe API samples

## Git
- [ ] Merge LDtk repo to `master`
- [ ] Merge LDtk Haxe API repo to `master`
- [ ] Update `Haxelib.json`
- [ ] Add "x.x.x-rcX" tag to Haxe API repo

## Deploy
- [ ] Run `npm run publish-github`
- [ ] Copy *Releases notes* to GitHub
- [ ] Build macOS and Linux distribs
- [ ] Attach macOS to GitHub Release
- [ ] Attach Linux to GitHub Release
- [ ] Build QuickType files

## Publish
- [ ] Upload HaxeLib
- [ ] Run `npm run publish-itchio`
- [ ] Upload macOS build to Itch.io
- [ ] Upload Linux build to Itch.io
- [ ] Upload Changelog to FTP
- [ ] Upload JSON Doc to FTP
- [ ] Upload JSON Schema to FTP
- [ ] Upload QuickType parsers
- [ ] Publish GitHub release

## Finalize
- [ ] Update Itch.io page
- [ ] Add a devlog post on Itch.io
- [ ] Announce on Twitter
- [ ] Announce on Discord
- [ ] Announce on Reddit (major releases only)
