# Publishes docker containers
[![Actions Status](https://github.com/TakeoffTech/Publish-Docker-Github-Action/workflows/Test/badge.svg)](https://github.com/TakeoffTech/Publish-Docker-Github-Action/actions)
[![Actions Status](https://github.com/TakeoffTech/Publish-Docker-Github-Action/workflows/Integration%20Test/badge.svg)](https://github.com/TakeoffTech/Publish-Docker-Github-Action/actions)
[![Actions Status](https://github.com/TakeoffTech/Publish-Docker-Github-Action/workflows/Integration%20Test%20Github/badge.svg)](https://github.com/TakeoffTech/Publish-Docker-Github-Action/actions)

This Action for [Docker](https://www.docker.com/) uses the Git branch as the [Docker tag](https://docs.docker.com/engine/reference/commandline/tag/) for building and pushing the container.
Hereby the master-branch is published as the latest-tag.

## Usage

## Example pipeline
```yaml
name: Publish Docker
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Publish to Registry
      uses: TakeoffTech/Publish-Docker-Github-Action@master
      with:
        name: myDocker/repository
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
```

## Mandatory Arguments

`name` is the name of the image you would like to push  
`username` the login username for the registry  
`password` the login password for the registry  

## Optional Arguments

### registry
Use `registry` for pushing to a custom registry

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  registry: gcr.io
```
#### docker.pkg.github.com registry
When using the docker.pkg.github.com registry, there is logic to build the correct url based upon the name and repository to set the correct imagename to use docker.pkg.github.com.

```yaml
with:
  name: container
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  registry: docker.pkg.github.com
```

With this the image url will be docker.pkg.github.com/someorg/somerepo/container:latest

### tagging

Use `tagging` to push an additional image, which is tagged with GITHUB_TAG.
When you would like to think about versioning images, this might be useful.

```yaml
if: contains(github.ref, 'refs/tags/v')
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  tagging: true
```

### snapshot
Use `snapshot` to push an additional image, which is tagged with {YEAR}{MONTH}{DAY}{HOUR}{MINUTE}{SECOND}{first 6 digits of the git sha}.  
The date was inserted to prevent new builds with external dependencies override older builds with the same sha.
When you would like to think about versioning images, this might be useful.  

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  snapshot: true
```

### dockerfile
Use `dockerfile` when you would like to explicitly build a Dockerfile.  
This might be useful when you have multiple DockerImages.  

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  dockerfile: MyDockerFileName
```

### cache
Use `cache` when you have big images, that you would only like to build partially (changed layers).  
> CAUTION: This will cache the non changed parts forever. If you use this option, make sure that these parts will be updated by another job!

```yaml
with:
  name: myDocker/repository
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}
  cache: true
```
