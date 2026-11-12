package app.qesma.service;

/** Body of "create an invite". All fields optional: 7 days, unlimited uses, no approval. */
public record InviteCommand(Integer expiresInDays, Integer maxUses, Boolean requiresApproval) {
}
