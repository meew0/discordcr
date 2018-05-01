#!/bin/bash

# Script adapted from https://gist.github.com/domenic/ec8b0fc8ab45f39403dd

set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="travis-tests"
TARGET_BRANCH="gh-pages"

function doCompile {
  echo "Generating docs..."
  crystal doc
  echo "Docs generated successfully."
}

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" ] || { [ "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ] && [ -z "$TRAVIS_TAG" ]; }; then
    echo "Skipping deploy; just doing a build."
    doCompile
    exit 0
fi

if [ -n "$TRAVIS_TAG" ]; then
    SOURCE_BRANCH=$TRAVIS_TAG
    echo "Tag build: $TRAVIS_TAG"
fi

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

echo "Cloning repo..."

# Clone the existing gh-pages for this repo into out/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
git clone $REPO out
cd out
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
cd ..

echo "Creating directories..."

mkdir -p out/doc/$SOURCE_BRANCH

# Clean out existing contents
rm -rf out/doc/$SOURCE_BRANCH/**/* || exit 0

# Run our compile script
doCompile

echo "Moving results..."

# Move results
mv docs/* out/doc/$SOURCE_BRANCH/

# Now let's go have some fun with the cloned repo
cd out
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
DIFF_RESULT=`git diff --exit-code`
if [ -z "$DIFF_RESULT" ]; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

echo "Committing..."

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add .
git commit -m "Deploy to GitHub Pages: ${SHA}"

echo "Getting deploy key..."

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

echo "Pushing..."

# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH

echo "All done!"
