package piedpiper.user_service.auth.dtos;

public record SignInDto(
        String login,
        String password
) {
}
