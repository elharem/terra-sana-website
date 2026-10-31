package com.terresana.backend.config;

import com.terresana.backend.model.Admin;
import com.terresana.backend.repository.AdminRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;
import java.util.List;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final VolunteerJwtUtil volunteerJwtUtil;
    private final AdminRepository adminRepository;

    public JwtFilter(JwtUtil jwtUtil, VolunteerJwtUtil volunteerJwtUtil, AdminRepository adminRepository) {
        this.jwtUtil = jwtUtil;
        this.volunteerJwtUtil = volunteerJwtUtil;
        this.adminRepository = adminRepository;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain chain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);

            // L'admin n'est authentifié que si son compte existe encore et reste actif.
            // Cela invalide les anciens JWT après désactivation ou suppression.
            if (jwtUtil.validateToken(token)) {
                String username = jwtUtil.extractUsername(token);
                adminRepository.findByUsername(username)
                        .filter(Admin::isActive)
                        .ifPresent(admin -> authenticate(admin.getUsername(), "ROLE_ADMIN"));
            } else if (volunteerJwtUtil.validateToken(token)) {
                authenticate(volunteerJwtUtil.extractUsername(token), "ROLE_VOLUNTEER");
            }
        }

        chain.doFilter(request, response);
    }

    private void authenticate(String username, String role) {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(
                        username, null, List.of(new SimpleGrantedAuthority(role)));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }
}
