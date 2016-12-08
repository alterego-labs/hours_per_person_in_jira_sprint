## Statistics calculation rules

For proper calculation this version of the script expects the following:

1. Story, bugstory, improvement, spike, task - are only containers, so their estimate won't be considered at all.
2. Each container has a bunch of subtasks which are assigned and have estimate.
3. Only estimates from the subtasks are used to calculate the statistics

This rules are important to make a right calculations, at least for the current version.

## Usage

Use the following guide:

```
$ bundle install
$ JIRA_USER_LOGIN='<LOGIN_OR_EMAIL>' JIRA_USER_PASSWORD='<PASSWORD>' JIRA_DOMAIN='<DOMAIN>' ruby script.rb
```
