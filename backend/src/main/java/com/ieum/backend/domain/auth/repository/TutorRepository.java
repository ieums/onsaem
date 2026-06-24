package com.ieum.backend.domain.auth.repository;

import com.ieum.backend.domain.auth.entity.AuthProvider;
import com.ieum.backend.domain.auth.entity.Tutor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TutorRepository extends JpaRepository<Tutor, Long> {

    Optional<Tutor> findByProviderAndProviderUserId(AuthProvider provider, String providerUserId);

    Optional<Tutor> findByEmail(String email);

    boolean existsByEmail(String email);

    List<Tutor> findAllByIdIn(List<Long> ids);
}