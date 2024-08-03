package piedpiper.user_service.auth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import piedpiper.user_service.auth.dtos.SignUpDto;
import piedpiper.user_service.auth.exception.InvalidJwtException;
import piedpiper.user_service.user.entity.User;
import piedpiper.user_service.user.repository.IUserRepository;

@Service
public class AuthService implements UserDetailsService {

    @Autowired
    IUserRepository repository;

    @Override
    public UserDetails loadUserByUsername(String username) {
        return repository.findByLogin(username);
    }

    public synchronized UserDetails signUp(SignUpDto data) throws InvalidJwtException {
        var user = repository.findByLogin(data.login());

        if (user != null) {
            throw new InvalidJwtException("Username already exists");
        }
        String encryptedPassword = new BCryptPasswordEncoder().encode(data.password());
        User newUser = new User(data.login(), encryptedPassword, data.role());
        return repository.save(newUser);
    }

}
