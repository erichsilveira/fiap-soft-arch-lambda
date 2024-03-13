package com.fiap.techchallenge.handler;

import com.amazonaws.services.cognitoidp.AWSCognitoIdentityProvider;
import com.amazonaws.services.cognitoidp.AWSCognitoIdentityProviderClientBuilder;
import com.amazonaws.services.cognitoidp.model.AdminInitiateAuthRequest;
import com.amazonaws.services.cognitoidp.model.AdminInitiateAuthResult;
import com.amazonaws.services.cognitoidp.model.AuthFlowType;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.Gson;

import java.util.HashMap;
import java.util.Map;

public class LambdaHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent> {

    @Override
    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent input, Context context) {

        APIGatewayProxyResponseEvent response = new APIGatewayProxyResponseEvent()
                .withHeaders(Map.of("Content-Type", "application/json"));

        JsonObject loginDetails = JsonParser.parseString(input.getBody()).getAsJsonObject();

        try {
            AWSCognitoIdentityProvider cognitoIdentityProviderClient = AWSCognitoIdentityProviderClientBuilder.defaultClient();

            Map<String, String> authParams = new HashMap<>();
            authParams.put("USERNAME", loginDetails.get("cpf").getAsString());
            authParams.put("PASSWORD", loginDetails.get("password").getAsString());

            AdminInitiateAuthRequest authRequest = new AdminInitiateAuthRequest()
                    .withAuthFlow(AuthFlowType.ADMIN_NO_SRP_AUTH)
                    .withUserPoolId(System.getenv("POOL_ID"))
                    .withClientId(System.getenv("CLIENT_ID"))
                    .withAuthParameters(authParams);

            AdminInitiateAuthResult authResult = cognitoIdentityProviderClient.adminInitiateAuth(authRequest);

            JsonObject result = new JsonObject();
            result.addProperty("token", authResult.getAuthenticationResult().getAccessToken());

            response.withStatusCode(200)
                    .withBody(new Gson().toJson(result, JsonObject.class));

        } catch (Exception e) {
            e.printStackTrace();
        }

        return response;
    }
}
