# Namespace
variable "codeartifact_repositories" {
  type = map(object({
      external_connections = map(object({
        external_connection_name  = string
      }))
      upstream_repos = map(object({
        repository_name  = string
      }))
      read_principals = list(string)
      publish_principals = list(string)
    })
  )
}

variable "domain" {
    type = string
}
