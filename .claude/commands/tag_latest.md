Create a tag based on the most recent tag value. Follow SEMVER and when in doubt, default to bumping patch versions first. You may analyze the last commits to the last tag to determine the version if necessary, and use that to prompt the user with a suggestion for a new tag for example one that bumps the major or minor versions.

All versions must be prefixed with lower case `v`.

Ask the user to verify the tag version before you push it to the remote repository.
