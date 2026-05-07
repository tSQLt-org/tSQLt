# tSQLt

Download the latest version at [tSQLt.org](http://tsqlt.org/downloads/).

tSQLt is a unit testing framework for Microsoft SQL Server. 
It is compatible with SQL Server 2005 (service pack 2 required) and above on all editions.

tSQLt allows you to implement unit tests in T-SQL. This is important as you do not have to switch between various tools to create your code and your unit tests. tSQLt also provides the following features to make it easier to create and manage unit tests:

* Tests are automatically run within transactions - this keeps tests independent and reduces any cleanup work you need
* Tests can be grouped together within a schema - allowing you to organize your tests and use common setup methods
* Output can be generated in plain text or XML - making it easier to integrate with a continuous integration tool

tSQLt is licensed under Apache 2.0 (https://github.com/tSQLt-org/tSQLt/blob/master/Build/License.txt)

---

## Development Setup

The recommended way to work on tSQLt is with the included dev container. It provides a fully configured environment with SQL Server 2022, PowerShell, mssql-tools, sqlpackage, mono, and all required VS Code extensions - no local installation needed beyond Docker and VS Code.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine on Linux)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Starting the dev container

0. Install "Dev Containers" extension in VS Code
1. Open the repository folder in VS Code.
2. When prompted "Reopen in Container", click it - or open the Command Palette (`Ctrl+Shift+P`) and run **Dev Containers: Reopen in Container**.
3. VS Code will build the container image and start SQL Server 2022 automatically. The first build takes a few minutes.

Once the container is ready, SQL Server is accessible at `localhost,1433` with credentials `sa` / `P@ssw0rd`.

### Build and deploy from source

Run the **Deploy: Build & Deploy tSQLt from Source** task (`Ctrl+Shift+B`) or via the Command Palette:

```
Terminal > Run Build Task
```

### Run unit tests

Run the **Test: Run tSQLt Unit Tests** task via the Command Palette:

```
Terminal > Run Test Task
```
