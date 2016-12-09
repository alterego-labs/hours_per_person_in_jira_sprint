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

## Statistics calculation rules

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
