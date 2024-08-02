package piedpiper.backend.exchange.auth.dtos;

public record SignInDto(
        String login,
        String password
) {
}
