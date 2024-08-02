package piedpiper.user_service.auth.dtos;


import piedpiper.user_service.role.types.Role;

public record SignUpDto(
        String login,
        String password,
        Role role
) {

}
