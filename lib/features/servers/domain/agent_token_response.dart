class AgentTokenResponse {
  final int serverId;
  final String agentToken;

  AgentTokenResponse({required this.serverId, required this.agentToken});

  factory AgentTokenResponse.fromCreateResponse(Map<String, dynamic> json) {
    return AgentTokenResponse(
      serverId: json['id'] as int,
      agentToken: json['agent_token'] as String,
    );
  }

  factory AgentTokenResponse.fromRegenerateResponse(Map<String, dynamic> json) {
    return AgentTokenResponse(
      serverId: json['server_id'] as int,
      agentToken: json['agent_token'] as String,
    );
  }
}
