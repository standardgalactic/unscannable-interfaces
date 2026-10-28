#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Run from ~/unscannable-interfaces. Creates a NEW public GitHub repository.
# Content: CC BY 4.0. Shell scripts: MIT. Review these choices before running.
set -euo pipefail

repo='standardgalactic/unscannable-interfaces'
holder="${COPYRIGHT_HOLDER:-Cogito Ergo Sum}"
year="$(date +%Y)"
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

for command in git gh curl; do
  command -v "$command" >/dev/null || die "Install $command first."
done
gh auth status --hostname github.com >/dev/null || die 'Run gh auth login first.'
[[ ! -e .git ]] || die 'This directory already has Git history; stopping without changing it.'
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  die 'This directory is inside another Git repository; move it outside that repository first.'
fi
git var GIT_AUTHOR_IDENT >/dev/null || die 'Configure git user.name and user.email first.'

required=(
  common_decency.tex common_decency.pdf
  adversarial-epistemic-closure.tex adversarial-epistemic-closure.pdf
  criminalization_of_association.tex criminalization_of_association.pdf
  How_Surveillance_Algorithms_Manufacture_Conspiracies.mp3
  Why_Peer_Review_Fails_to_Self_Correct.mp3
  How_Markets_Flatten_Human_Identity.mp3
  How_Surveillance_Algorithms_Manufacture_Conspiracies.txt
  Why_Peer_Review_Fails_to_Self_Correct.txt
  How_Markets_Flatten_Human_Identity.txt
  How_Surveillance_Algorithms_Manufacture_Conspiracies.vtt
  Why_Peer_Review_Fails_to_Self_Correct.vtt
  How_Markets_Flatten_Human_Identity.vtt
  fix_transcription_errors.sh README.md
)
for file in "${required[@]}"; do
  [[ -f "$file" && ! -L "$file" && -r "$file" ]] || die "Missing, unreadable, or symlinked file: $file"
done
for file in LICENSE LICENSE-CODE LICENSING.md; do
  [[ ! -e "$file" ]] || die "$file already exists; review the existing license first."
done

# Fetch the complete official license before making local repository changes.
license_temp="$(mktemp)"
trap 'rm -f -- "$license_temp"' EXIT
curl --fail --silent --show-error --location --retry 2 \
  https://creativecommons.org/licenses/by/4.0/legalcode.txt -o "$license_temp"
grep -q 'Attribution 4.0 International' "$license_temp" || die 'Unexpected license download.'

# Create by name rather than pushing to the old URL first. If that URL merely
# redirects to a renamed repository, creation reclaims the original name.
# If a real repository occupies this name, creation fails and nothing is pushed.
gh repo create "$repo" --public \
  --description 'Papers, audio discussions, and transcripts on unscannable interfaces'

cp -- "$license_temp" LICENSE
cat > LICENSE-CODE <<EOF
MIT License

Copyright (c) $year $holder

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
cat > LICENSING.md <<EOF
# Licensing

Copyright (c) $year $holder, for original material owned by the author.

The papers, LaTeX sources, audio recordings, transcripts, captions, and README
are licensed under Creative Commons Attribution 4.0 International (CC BY 4.0).
The full terms are in [LICENSE](LICENSE):
https://creativecommons.org/licenses/by/4.0/.

Shell scripts are licensed under the MIT License in [LICENSE-CODE](LICENSE-CODE).
Third-party material remains subject to its original terms; these licenses
cover only rights the author is entitled to grant.
EOF
cat >> README.md <<'EOF'

## License

Papers, sources, audio, transcripts, and captions: [CC BY 4.0](LICENSE).
Shell scripts: [MIT](LICENSE-CODE). See [LICENSING.md](LICENSING.md).
EOF

git init -b main
git add -- "${required[@]}" LICENSE LICENSE-CODE LICENSING.md
# Include the deploy script when it was saved in this source directory.
if [[ -f deploy-unscannable-interfaces.sh && ! -L deploy-unscannable-interfaces.sh ]]; then
  git add -- deploy-unscannable-interfaces.sh
fi
git commit -m 'Publish papers, audio, transcripts, and licenses'
git remote add origin "https://github.com/$repo.git"
git push -u origin main
printf '\nPublished: https://github.com/%s\n' "$repo"

# If a network or authentication failure interrupts the final push, recover with:
#   git push -u origin main
# This script creates a repository only; it does not configure GitHub Pages.
# corrections.log and TeX build intermediates are intentionally not staged.

