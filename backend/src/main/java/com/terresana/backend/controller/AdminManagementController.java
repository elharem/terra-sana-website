package com.terresana.backend.controller;

import com.terresana.backend.config.JwtUtil;
import com.terresana.backend.model.Admin;
import com.terresana.backend.repository.AdminRepository;
import com.terresana.backend.repository.BlogPostRepository;
import com.terresana.backend.repository.ContactMessageRepository;
import com.terresana.backend.repository.EventRepository;
import com.terresana.backend.repository.RegistrationRepository;
import com.terresana.backend.repository.ProjectRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/auth/admins")
@CrossOrigin(origins = "*")
public class AdminManagementController {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private final AdminRepository adminRepository;
    private final ProjectRepository projectRepository;
    private final BlogPostRepository blogPostRepository;
    private final ContactMessageRepository contactMessageRepository;
    private final EventRepository eventRepository;
    private final RegistrationRepository registrationRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AdminManagementController(
            AdminRepository adminRepository,
            ProjectRepository projectRepository,
            BlogPostRepository blogPostRepository,
            ContactMessageRepository contactMessageRepository,
            EventRepository eventRepository,
            RegistrationRepository registrationRepository,
            PasswordEncoder passwordEncoder,
            JwtUtil jwtUtil) {
        this.adminRepository = adminRepository;
        this.projectRepository = projectRepository;
        this.blogPostRepository = blogPostRepository;
        this.contactMessageRepository = contactMessageRepository;
        this.eventRepository = eventRepository;
        this.registrationRepository = registrationRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    // Renvoie uniquement les champs nécessaires à l'écran ; jamais le hash du mot de passe.
    @GetMapping
    public List<Map<String, Object>> listAdmins() {
        return adminRepository.findAll().stream()
                .sorted(Comparator.comparing(Admin::getUsername, String.CASE_INSENSITIVE_ORDER))
                .map(this::toAdminDto)
                .toList();
    }

    @PutMapping("/{id}/profile")
    public Map<String, String> updateProfile(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        Admin admin = findAdmin(id);
        String username = body.get("username");
        String email = normalizeEmail(body.get("email"));
        validateProfile(username, email);
        username = username.trim();

        final String cleanUsername = username;
        boolean usernameUsed = adminRepository.findByUsername(cleanUsername)
                .filter(other -> !other.getId().equals(id)).isPresent();
        boolean emailUsed = adminRepository.findByEmail(email)
                .filter(other -> !other.getId().equals(id)).isPresent();
        if (usernameUsed) throw new RuntimeException("Ce nom d'utilisateur est déjà utilisé.");
        if (emailUsed) throw new RuntimeException("Cette adresse e-mail est déjà utilisée.");

        String currentUsername = getUsername(request);
        boolean editingSelf = admin.getUsername().equals(currentUsername);
        admin.setUsername(cleanUsername);
        admin.setEmail(email);
        adminRepository.save(admin);

        Map<String, String> result = new HashMap<>();
        result.put("message", "Compte administrateur modifié avec succès.");
        if (editingSelf) {
            result.put("token", jwtUtil.generateToken(cleanUsername));
        }
        return result;
    }

    @PutMapping("/{id}/password")
    public Map<String, String> changeAdminPassword(
            @PathVariable Long id, @RequestBody Map<String, String> body) {
        String newPassword = body.get("newPassword");
        if (newPassword == null || newPassword.length() < 8) {
            throw new RuntimeException("Le mot de passe doit contenir au moins 8 caractères.");
        }
        Admin admin = findAdmin(id);
        admin.setPassword(passwordEncoder.encode(newPassword));
        adminRepository.save(admin);
        return Map.of("message", "Mot de passe administrateur modifié avec succès.");
    }

    @PutMapping("/{id}/toggle-active")
    @Transactional
    public Map<String, String> toggleActive(@PathVariable Long id, HttpServletRequest request) {
        Admin admin = findAdmin(id);
        String actor = getUsername(request);
        if (admin.getUsername().equals(actor)) {
            throw new RuntimeException("Vous ne pouvez pas désactiver votre propre compte.");
        }
        if (admin.isActive() && adminRepository.countByActiveTrue() <= 1) {
            throw new RuntimeException("Impossible de désactiver le dernier administrateur actif.");
        }
        admin.setActive(!admin.isActive());
        adminRepository.save(admin);
        return Map.of("message", admin.isActive()
                ? "Compte administrateur réactivé."
                : "Compte administrateur désactivé.");
    }

    @DeleteMapping("/{id}")
    @Transactional
    public Map<String, String> deleteAdmin(@PathVariable Long id, HttpServletRequest request) {
        Admin admin = findAdmin(id);
        String actor = getUsername(request);
        if (admin.getUsername().equals(actor)) {
            throw new RuntimeException("Vous ne pouvez pas supprimer votre propre compte.");
        }
        if (admin.isActive() && adminRepository.countByActiveTrue() <= 1) {
            throw new RuntimeException("Impossible de supprimer le dernier administrateur actif.");
        }

        // Admin possède des cascades JPA vers ces données : on bloque la suppression pour les préserver.
        boolean hasContent = projectRepository.existsByAdmin(admin)
                || blogPostRepository.existsByAdmin(admin)
                || contactMessageRepository.existsByAdmin(admin)
                || eventRepository.existsByAdmin(admin)
                || registrationRepository.existsByValidatedBy(admin);
        if (hasContent) {
            throw new RuntimeException(
                    "Suppression refusée : cet administrateur est associé à des événements, inscriptions, projets, articles ou messages. Désactivez plutôt son compte.");
        }

        adminRepository.delete(admin);
        return Map.of("message", "Administrateur supprimé avec succès.");
    }

    private Admin findAdmin(Long id) {
        return adminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Administrateur introuvable."));
    }

    private String getUsername(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            throw new RuntimeException("Token manquant ou invalide.");
        }
        return jwtUtil.extractUsername(header.substring(7));
    }

    private String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
    }

    private void validateProfile(String username, String email) {
        if (username == null || username.isBlank()) {
            throw new RuntimeException("Le nom d'utilisateur est obligatoire.");
        }
        if (!EMAIL_PATTERN.matcher(email).matches()) {
            throw new RuntimeException("L'adresse e-mail est invalide.");
        }
    }

    private Map<String, Object> toAdminDto(Admin admin) {
        Map<String, Object> dto = new HashMap<>();
        dto.put("id", admin.getId());
        dto.put("username", admin.getUsername());
        dto.put("email", admin.getEmail() == null ? "" : admin.getEmail());
        dto.put("active", admin.isActive());
        return dto;
    }
}
