## Usage

Use the following flow:

```shell
$ bundle install
$ JIRA_USER_LOGIN='<LOGIN_OR_EMAIL>' JIRA_USER_PASSWORD='<PASSWORD>' JIRA_DOMAIN='<DOMAIN>' ruby script.rb
```

or from version _v1.0.2_ you can use the next simplified flow:

```bash
$ cp .env.example .env
$ vim .env # adjust ENV variables
$ ./run.sh
```

### Rich CLI options (_since v1.1.0_)

Run the following command:

```bash
$ ./run.sh --help
```

The output will be the next:

```bash
Usage: example.rb [options]
    -b, --board=BOARD                An ID of a board
    -s, --sprint=SPRINT              An ID of a sprint
    -h, --help                       Prints this help
```

So, now, instead selecting board and sprint every run, you can preselect both or one of those options via the CLI options.
For example:

```bash
$ ./run.sh --board=2 --sprint=147
```

And the program won't ask you to select board and sprint! This improvement can speed up the workflow for getting the main information - a table with hours per person. Of course, using CLI options is very handy if you already know board and spring IDs.

## Versions

### Version _v1.1.0_

* __FEATURE__: rich CLI options implementation to be able to preselect board and sprint

### Version _v1.0.3_

* __IMPROVEMENT__: code refactoring
* __FEATURE__: show spent hours and remaining hours per person

### Version _v1.0.2_

* __IMPROVEMENT__: provide simplified flow to run statistics generator

### Version _v1.0.1_

Improvement has been made regarding the logic to select meaningful tasks:

* if Task has no subtasks then it is considered as a subtask and will be used in the statistics calculations.

### Version _v1.0.0_

For proper calculation this version of the script expects the following:

1. Story, bugstory, improvement, spike, task - are only containers, so their estimate won't be considered at all.
2. Each container has a bunch of subtasks which are assigned and have estimate.
3. Only estimates from the subtasks are used to calculate the statistics

This rules are important to make a right calculations, at least for the current version.
