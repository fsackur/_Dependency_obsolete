# Dependency

A module for working with PS module dependencies.

## Terminology

- _Depending module_ : a module that requires other modules to be imported before it can be loaded.
- _Dependency module_ : a module that must be imported before some other module can be loaded.
- _Module specification_ : an object of type `[Microsoft.PowerShell.Commands.ModuleSpecification]` which defines a module's name and version.

This module works with module manifests (aka .psd1 files) and examines the `RequiredModules` field. Modules that are required by `#requires` statements will not play nicely.

## Overview

Provide `Get-ModuleDependency` with a depending module for which you need to examine or import other modules. The command looks at the module manifest, then finds the dependency modules defined in the `RequiredModules` field.

The algorithm to find the dependency modules is pluggable. A base implementation is provided in the `Get-ManifestFinder` command. This command outputs a scriptblock that accepts a module specification object and returns the manifest contents of that module. The scriptblock searches the containing folder of the provided module.

However, you can extend the functionality to search other module repositories, for example, Github, by providing any scriptblock that accepts a module specification object and returns the manifest content of that module as a hashtable.