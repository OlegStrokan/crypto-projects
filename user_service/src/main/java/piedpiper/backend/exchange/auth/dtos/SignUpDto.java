package piedpiper.backend.exchange.auth.dtos;


import piedpiper.backend.exchange.role.types.Role;

public record SignUpDto(
        String login,
        String password,
        Role role
) {

}
