# linear_client

Cliente Ruby puro para a [API GraphQL do Linear](https://developers.linear.app/docs/graphql/working-with-the-graphql-api) — sem gems externas, apenas a stdlib (`net/http`, `uri`, `json`).

Não há SDK oficial para Ruby; este projeto preenche essa lacuna com uma interface simples para criar issues, comentar e consultar dados no Linear.

## Instalação

Ainda não publicada no RubyGems. Por enquanto, use direto do GitHub:

```ruby
# Gemfile
gem "linear_client", github: "ferretto/linear_client"
```

ou clone e exija localmente:

```ruby
$LOAD_PATH.unshift File.expand_path("linear_client/lib", __dir__)
require "linear_client"
```

## Configuração

1. Gere uma API key pessoal no Linear em `Settings > Account > Security > API keys`.
2. Exporte a chave como variável de ambiente (nunca hardcode no código):

```bash
export LINEAR_API_KEY="lin_api_xxxxxxxx"
```

> Trate a API key como uma senha: não a compartilhe, não a commit em arquivos versionados, e revogue/gere outra se ela vazar.

## Uso

```ruby
require "linear_client"

client = LinearClient::Client.new
# ou, explicitamente:
client = LinearClient::Client.new(api_key: "lin_api_xxxxxxxx")
```

### Descobrir times

```ruby
client.teams
# => [{"id"=>"...", "name"=>"Engineering", "key"=>"ENG"}, ...]
```

### Criar um card e comentar

```ruby
result = client.create_issue(team_id: "TEAM_ID", title: "Bug no login", description: "Detalhes...")
issue_id = result.dig("issue", "id")

client.create_comment(issue_id: issue_id, body: "Já reproduzi, investigando.")
```

### Listar issues atribuídas a você

```ruby
client.my_issues.each { |i| puts "#{i['identifier']} [#{i['state']['name']}] #{i['title']}" }
```

### Dados do usuário autenticado

```ruby
client.viewer
# => {"name"=>"...", "email"=>"..."}
```

## Referência da API

| Método | Descrição | Retorno |
|---|---|---|
| `teams` | Lista os times do workspace (`id`, `name`, `key`) | `Array<Hash>` |
| `viewer` | Nome e e-mail do dono da API key | `Hash` |
| `my_issues` | Issues atribuídas ao dono da API key, com prioridade, datas, estado e time | `Array<Hash>` |
| `create_issue(team_id:, title:, description: nil)` | Cria um card num time | `Hash` com `"success"` e `"issue"` (`id`, `identifier`, `title`, `url`) |
| `create_comment(issue_id:, body:)` | Comenta num card existente | `Hash` com `"success"` e `"comment"` (`id`, `url`) |

Todos os métodos lançam `LinearClient::Client::Error` se a API retornar erros GraphQL.

## Testes

Suíte em RSpec, com [WebMock](https://github.com/bblimke/webmock) simulando as respostas da API (nenhum teste bate na rede real):

```bash
bundle install
bundle exec rspec
```

## Scripts de exemplo

```bash
# Lista os times e cria um card de teste no time indicado pelo key (ex: ENG)
ruby examples/create_issue.rb ENG

# Lista as issues atribuídas a você
ruby examples/my_issues.rb

# Exporta viewer + issues atribuídas para JSON
ruby examples/report.rb caminho/para/saida.json
```

## Notas de segurança

- A API key vai no header `Authorization` (sem prefixo `Bearer`), conforme exigido pela API do Linear.
- Nunca dê commit em arquivos `.env` ou qualquer arquivo com a chave em texto puro — este repositório já ignora `.env` via `.gitignore`.

## Licença

[MIT](LICENSE)
