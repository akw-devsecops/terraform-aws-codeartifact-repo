resource "aws_codeartifact_domain" "domain" {
  domain = var.domain
}

resource "aws_codeartifact_repository" "repo" {
  for_each = var.codeartifact_repositories

  repository = each.key
  domain     = aws_codeartifact_domain.domain.domain

  dynamic "external_connections" {
    for_each = each.value.external_connections

    content {
      external_connection_name = external_connections.value["external_connection_name"]
    }
  }

  dynamic "upstream" {
    for_each = each.value.upstream_repos

    content {
      repository_name = upstream.value["repository_name"]
    }
  }
}

data "aws_iam_policy_document" "repo" {
  for_each = var.codeartifact_repositories

  dynamic "statement" {
    for_each = [for k in each.value.read_principals : k if index(each.value.read_principals, k) == 0]

    content {
      sid    = "read"
      effect = "Allow"
      actions = [
        "codeartifact:Get*",
        "codeartifact:List*",
        "codeartifact:Describe*",
        "codeartifact:Read*"
      ]
      resources = [
        "*" # required
      ]
      principals {
        type        = "AWS"
        identifiers = each.value.read_principals
      }
    }
  }

  dynamic "statement" {
    for_each = [for k in each.value.publish_principals : k if index(each.value.publish_principals, k) == 0]

    content {
      sid    = "publish"
      effect = "Allow"
      actions = [
        "codeartifact:Get*",
        "codeartifact:List*",
        "codeartifact:Describe*",
        "codeartifact:Read*",
        "codeartifact:*Package*"
      ]
      resources = [
        "*" # required
      ]

      principals {
        type        = "AWS"
        identifiers = each.value.publish_principals
      }
    }
  }
}

resource "aws_codeartifact_domain_permissions_policy" "domain" {
  domain          = aws_codeartifact_domain.domain.domain
  policy_document = data.aws_iam_policy_document.domain.json
}

data "aws_iam_policy_document" "domain" {
  statement {
    sid    = "getAuthToken"
    effect = "Allow"
    actions = [
      "codeartifact:GetAuthorizationToken"
    ]
    resources = [
      aws_codeartifact_domain.domain.arn
    ]
    principals {
      type = "AWS"
      identifiers = distinct(flatten([
        for repo in var.codeartifact_repositories : [
          concat(repo.publish_principals, repo.read_principals)
        ]
      ]))
    }
  }
}

resource "aws_codeartifact_repository_permissions_policy" "account_read" {
  for_each = var.codeartifact_repositories

  repository      = aws_codeartifact_repository.repo[each.key].repository
  domain          = aws_codeartifact_domain.domain.domain
  policy_document = data.aws_iam_policy_document.repo[each.key].json
}
