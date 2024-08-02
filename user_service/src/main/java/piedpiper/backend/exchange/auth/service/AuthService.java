package piedpiper.backend.exchange.auth.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import piedpiper.backend.exchange.auth.dtos.SignUpDto;
import piedpiper.backend.exchange.auth.exception.InvalidJwtException;
import piedpiper.backend.exchange.user.entity.User;
import piedpiper.backend.exchange.user.repository.IUserRepository;

@Service
public class AuthService implements UserDetailsService {

    @Autowired
    IUserRepository repository;

    @Override
    public UserDetails loadUserByUsername(String username) {
        return repository.findByLogin(username);
    }

    public UserDetails signUp(SignUpDto data) throws InvalidJwtException {
        var user = repository.findByLogin(data.login());

        if (user != null) {
            throw new InvalidJwtException("Username already exists");
        }
        String encryptedPassword = new BCryptPasswordEncoder().encode(data.password());
        User newUser = new User(data.login(), encryptedPassword, data.role());
        return repository.save(newUser);
    }

}
