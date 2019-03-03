# Dependency

A module for working with PS module dependencies.

## Terminology

- _Depending module_ : a module that requires other modules to be imported before it can be loaded.
- _Dependency module_ : a module that must be imported before some other module can be loaded.
- _Module specification_ : an object of type `[Microsoft.PowerShell.Commands.ModuleSpecification]` which defines a module's name and version.

This module works with module manifests (aka .psd1 files) and examines the `RequiredModules` field. (Modules that are required by `#requires` statements will not play nicely.)

## Overview

Let's say you have a Powershell module, `Module1`, and you want to run a command from it on a remote machine. You're going to have to copy `Module1` to the remote machine first, so that you can import it; then the command will be available.

Let's say that `Module1` requires specific versions of `Module2` and `Module3`, and `Module2` in turn requires `Module4`:

``` none
Module1 v1.0.2.3
|
├───Module2 v2.2
|   |
│   └───Module4 v1.7.1
|
└───Module3 v1.1.9.1
```

Copying `Module1` alone won't suffice, because you can't import it if the dependencies are not met. So now you have to copy the other three modules as well.

_And_ they have to be of the correct version. It's no good copying version `1.0` of `Module4`, because it won't satisfy the requirement for version `1.7.1`; and if `Module2` requires version `1.7.1` of `Module4` strictly, then it's no good copying version `1.8` either.

This is where `Dependency` steps in. `Dependency` will gather all the modules required for any given module, picking a version that satisifies the dependency specification, from whatever you use as a repository.
