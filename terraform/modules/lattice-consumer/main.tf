# Accept RAM invitation only if still pending (idempotent for re-applies).
resource "terraform_data" "accept_ram_share" {
  input = var.resource_share_arn

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      INVITATION=$(aws ram get-resource-share-invitations \
        --region "${var.aws_region}" \
        --resource-share-arns "${var.resource_share_arn}" \
        --query "resourceShareInvitations[?status=='PENDING'].resourceShareInvitationArn | [0]" \
        --output text)
      if [ -n "$${INVITATION}" ] && [ "$${INVITATION}" != "None" ] && [ "$${INVITATION}" != "null" ]; then
        aws ram accept-resource-share-invitation \
          --region "${var.aws_region}" \
          --resource-share-invitation-arn "$${INVITATION}"
      fi
    EOT
  }
}

resource "aws_vpclattice_service_network_vpc_association" "this" {
  service_network_identifier = var.service_network_arn
  vpc_identifier             = var.vpc_id

  depends_on = [terraform_data.accept_ram_share]
}
