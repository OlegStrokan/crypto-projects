package piedpiper.backend.exchange.user.repository;

import org.springframework.security.core.userdetails.UserDetails;
import piedpiper.backend.exchange.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface IUserRepository extends JpaRepository<User, Long> {
    UserDetails findByLogin(String login);
}
