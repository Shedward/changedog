# ChangeDog

Отправляет в слак сводку по всем тегам за последние сутки с упомянутыми в этом релизе задачами из Jira

# Использование 

```
changedog ./path/to/configuration.json
```

# Формат конфигурации

```
{
	"gitlabHost": "<gitlab host>",
	"gitlabProjectId": "<gitlab project id>",
	"gitlabToken": "<gitlab token>",

	"jiraHost": "<jira host>",
	"jiraUsername": "<jira username>",
	"jiraToken": "<jira password>",

	"slackHost": "<slack host>",
	"slackChannel": "<slack channel>"
}
```

# Установка 

```
brew tap shedward/changedog git@github.com:Shedward/changedog.git
brew install --build-from-source changedog
```

#  Удаление

```
brew uninstall changedog
```