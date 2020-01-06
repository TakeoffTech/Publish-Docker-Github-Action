#!/bin/sh -e

function cleanEnvironment() {
  unset INPUT_TAGGING
  unset INPUT_SNAPSHOT
  unset INPUT_DOCKERFILE
  unset INPUT_REGISTRY
  unset INPUT_CACHE
  unset GITHUB_SHA
  unset GITHUB_REPOSITORY
}

function itPushesToGitHubRegistry() {
  export GITHUB_REF='refs/heads/master'
  export GITHUB_REPOSITORY='SomeOrg/SomeRepo'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='container'
  export INPUT_REGISTRY='docker.pkg.github.com'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin docker.pkg.github.com
Called mock with: build -t docker.pkg.github.com/someorg/somerepo/container:latest .
Called mock with: push docker.pkg.github.com/someorg/somerepo/container:latest
Called mock with: logout
::set-output name=IMAGE_URL::docker.pkg.github.com/someorg/somerepo/container:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
cleanEnvironment
}

function itPushesToGitHubRegistryBranch() {
  export GITHUB_REF='refs/heads/test/branch'
  export GITHUB_REPOSITORY='SomeOrg/SomeRepo'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='container'
  export INPUT_REGISTRY='docker.pkg.github.com'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin docker.pkg.github.com
Called mock with: build -t docker.pkg.github.com/someorg/somerepo/container:branch .
Called mock with: push docker.pkg.github.com/someorg/somerepo/container:branch
Called mock with: logout
::set-output name=IMAGE_URL::docker.pkg.github.com/someorg/somerepo/container:branch"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
cleanEnvironment
}

function itPushesMasterBranchToLatest() {
  export GITHUB_REF='refs/heads/master'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesBranchAsNameOfTheBranch() {
  export GITHUB_REF='refs/heads/myBranch'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:myBranch .
Called mock with: push my/repository:myBranch
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:myBranch"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itPushesSpecificDockerfileReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_DOCKERFILE='MyDockerFileName'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -f MyDockerFileName -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesSpecificDockerfilePathReleasesToLatest() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_DOCKERFILE='path/to/MyDockerFileName'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -f path/to/MyDockerFileName -t my/repository:latest path/to
Called mock with: push my/repository:latest
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesBranchByShaAndDateInAddition() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_SNAPSHOT='true'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
::set-output name=IMAGE_SHA_NAME::my/repository:19700101010112169e
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itCachesImageFromFormerBuildAndUsesItForSnapshotIfConfigured() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
::set-output name=IMAGE_SHA_NAME::my/repository:19700101010112169e
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itPushesBranchByShaAndDateInAdditionWithSpecificDockerfile() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_SNAPSHOT='true'
  export INPUT_DOCKERFILE='MyDockerFileName'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: build -f MyDockerFileName -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
::set-output name=IMAGE_SHA_NAME::my/repository:19700101010112169e
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itCachesImageFromFormerBuildAndUsesItForSnapshotIfConfiguredIsOkWithSpecificDockerfile() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  export GITHUB_SHA='12169ed809255604e557a82617264e9c373faca7'
  export MOCK_DATE='197001010101'
  export INPUT_SNAPSHOT='true'
  export INPUT_CACHE='true'
  export INPUT_DOCKERFILE='MyDockerFileName'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build -f MyDockerFileName --cache-from my/repository:latest -t my/repository:latest -t my/repository:19700101010112169e .
Called mock with: push my/repository:latest
Called mock with: push my/repository:19700101010112169e
::set-output name=IMAGE_SHA_NAME::my/repository:19700101010112169e
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itCachesImageFromFormerBuildAndUsesItTaggingIfConfigured() {
  export GITHUB_REF='refs/tags/v0.5.0'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  export INPUT_TAGGING='true'
  export INPUT_CACHE='true'
  export INPUT_DOCKERFILE='MyDockerFileName'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build -f MyDockerFileName --cache-from my/repository:latest -t my/repository:latest -t my/repository:0.5.0 .
Called mock with: push my/repository:latest
Called mock with: push my/repository:0.5.0
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:0.5.0"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itLogsIntoAnotherRegistryIfConfigured() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_REGISTRY='https://myRegistry'
  export INPUT_NAME='my/repository'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin https://myRegistry
Called mock with: build -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itCachesImageFromFormerBuildIfConfigured() {
  export GITHUB_REF='refs/tags/myRelease'
  export INPUT_USERNAME='USERNAME'
  export INPUT_PASSWORD='PASSWORD'
  export INPUT_NAME='my/repository'
  export INPUT_CACHE='true'
  local result=$(exec /entrypoint.sh)
  local expected="Called mock with: login -u USERNAME --password-stdin
Called mock with: pull my/repository:latest
Called mock with: build --cache-from my/repository:latest -t my/repository:latest .
Called mock with: push my/repository:latest
Called mock with: logout
::set-output name=IMAGE_URL::my/repository:latest"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
  cleanEnvironment
}

function itErrorsWhenNameWasNotSet() {
  unset INPUT_NAME
  local result=$(exec /entrypoint.sh)
  local expected="Unable to find the repository name. Did you set with.name?"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itErrorsWhenUsernameWasNotSet() {
  export INPUT_NAME='my/repository'
  unset INPUT_USERNAME
  local result=$(exec /entrypoint.sh)
  local expected="Unable to find the username. Did you set with.username?"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

function itErrorsWhenPasswordWasNotSet() {
  export INPUT_NAME='my/repository'
  export INPUT_USERNAME='USERNAME'
  unset INPUT_PASSWORD
  local result=$(exec /entrypoint.sh)
  local expected="Unable to find the password. Did you set with.password?"
  if [ "$result" != "$expected" ]; then
    echo "Expected: $expected
    Got: $result"
    exit 1
  fi
}

itPushesToGitHubRegistry
itPushesToGitHubRegistryBranch
itPushesMasterBranchToLatest
itPushesBranchAsNameOfTheBranch
itPushesReleasesToLatest
itPushesSpecificDockerfileReleasesToLatest
itPushesSpecificDockerfilePathReleasesToLatest
itPushesBranchByShaAndDateInAddition
itCachesImageFromFormerBuildAndUsesItForSnapshotIfConfigured
itPushesBranchByShaAndDateInAdditionWithSpecificDockerfile
itCachesImageFromFormerBuildAndUsesItTaggingIfConfigured
itLogsIntoAnotherRegistryIfConfigured
itCachesImageFromFormerBuildIfConfigured
itErrorsWhenNameWasNotSet
itErrorsWhenUsernameWasNotSet
itErrorsWhenPasswordWasNotSet
