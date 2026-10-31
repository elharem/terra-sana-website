package com.terresana.backend.controller;

import com.terresana.backend.config.JwtUtil;
import com.terresana.backend.model.Admin;
import com.terresana.backend.repository.AdminRepository;
import com.terresana.backend.service.EmailService;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private final AdminRepository adminRepo;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    public AuthController(
            AdminRepository adminRepo,
            JwtUtil jwtUtil,
            PasswordEncoder passwordEncoder,
            EmailService emailService) {
        this.adminRepo = adminRepo;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    @PostMapping("/login")
    public Map<String, String> login(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String password = body.get("password");

        if (username == null || username.isBlank()
                || password == null || password.isBlank()) {
            throw new RuntimeException("Le nom d'utilisateur et le mot de passe sont obligatoires.");
        }

        Admin admin = adminRepo.findByUsername(username.trim())
                .orElseThrow(() -> new RuntimeException("Admin non trouvé."));

        if (!admin.isActive()) {
            throw new RuntimeException("Ce compte administrateur est désactivé.");
        }
        if (!passwordEncoder.matches(password, admin.getPassword())) {
            throw new RuntimeException("Mot de passe incorrect.");
        }

        return Map.of("token", jwtUtil.generateToken(admin.getUsername()));
    }

    // Création du premier admin uniquement.
    // La règle de sécurité laisse cette route accessible, mais cette vérification
    // empêche de créer d'autres admins sans être connecté.
    @PostMapping("/register")
    public Map<String, String> register(@RequestBody Map<String, String> body) {
        if (adminRepo.count() > 0) {
            throw new RuntimeException("Un compte administrateur existe déjà.");
        }

        String username = body.get("username");
        String email = normalizeEmail(body.get("email"));
        String password = body.get("password");

        validateAdminFields(username, email, password);

        Admin admin = new Admin();
        admin.setUsername(username.trim());
        admin.setEmail(email);
        admin.setPassword(passwordEncoder.encode(password));
        adminRepo.save(admin);

        return Map.of("message", "Premier administrateur créé avec succès.");
    }

    // Création d'un admin supplémentaire par un admin déjà connecté.
    @PostMapping("/admins")
    public Map<String, String> createAdmin(@RequestBody Map<String, String> body) {
        String username = body.get("username");
        String email = normalizeEmail(body.get("email"));
        String password = body.get("password");

        validateAdminFields(username, email, password);

        String cleanUsername = username.trim();

        if (adminRepo.existsByUsername(cleanUsername)) {
            throw new RuntimeException("Ce nom d'utilisateur est déjà utilisé.");
        }
        if (adminRepo.existsByEmail(email)) {
            throw new RuntimeException("Cette adresse e-mail est déjà utilisée.");
        }

        Admin admin = new Admin();
        admin.setUsername(cleanUsername);
        admin.setEmail(email);
        admin.setPassword(passwordEncoder.encode(password));
        adminRepo.save(admin);

        return Map.of("message", "Administrateur ajouté avec succès.");
    }

    // Données du compte connecté pour remplir le formulaire « Mon compte ».
    @GetMapping("/me")
    public Map<String, String> getCurrentAdmin(HttpServletRequest request) {
        String username = getUsernameFromRequest(request);

        Admin admin = adminRepo.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Admin non trouvé."));

        Map<String, String> profile = new HashMap<>();
        profile.put("id", String.valueOf(admin.getId()));
        profile.put("username", admin.getUsername());
        profile.put("email", admin.getEmail() == null ? "" : admin.getEmail());

        return profile;
    }

    @PutMapping("/changePassword")
    public Map<String, String> changePassword(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        String username = getUsernameFromRequest(request);
        String oldPassword = body.get("oldPassword");
        String newPassword = body.get("newPassword");

        Admin admin = adminRepo.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Admin non trouvé."));

        if (oldPassword == null || oldPassword.isBlank()
                || !passwordEncoder.matches(oldPassword, admin.getPassword())) {
            throw new RuntimeException("Ancien mot de passe incorrect.");
        }

        if (newPassword == null || newPassword.length() < 8) {
            throw new RuntimeException("Le nouveau mot de passe doit contenir au moins 8 caractères.");
        }

        admin.setPassword(passwordEncoder.encode(newPassword));
        adminRepo.save(admin);

        return Map.of("message", "Mot de passe modifié avec succès.");
    }

    @PostMapping("/forgotPassword")
    public Map<String, String> forgotPassword(@RequestBody Map<String, String> body) {
        String username = body.get("username");

        Admin admin = adminRepo.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Admin non trouvé."));

        if (admin.getEmail() == null || admin.getEmail().isBlank()) {
            throw new RuntimeException("Aucune adresse e-mail n'est enregistrée pour cet admin.");
        }

        String token = jwtUtil.generatePasswordResetToken(admin.getUsername());
        emailService.sendAdminPasswordReset(admin, token);

        return Map.of("message", "E-mail de réinitialisation envoyé.");
    }

    @PostMapping("/resetPassword")
    public Map<String, String> resetPassword(@RequestBody Map<String, String> body) {
        String newPassword = body.get("newPassword");

        if (newPassword == null || newPassword.length() < 8) {
            throw new RuntimeException("Le nouveau mot de passe doit contenir au moins 8 caractères.");
        }

        String username;
        try {
            username = jwtUtil.extractUsernameFromResetToken(body.get("token"));
        } catch (JwtException e) {
            throw new RuntimeException("Ce lien est invalide ou a expiré.");
        }

        Admin admin = adminRepo.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Admin non trouvé."));

        admin.setPassword(passwordEncoder.encode(newPassword));
        adminRepo.save(admin);

        return Map.of("message", "Mot de passe réinitialisé avec succès.");
    }

    @PutMapping("/updateProfile")
    public Map<String, String> updateProfile(
            @RequestBody Map<String, String> body,
            HttpServletRequest request) {

        String currentUsername = getUsernameFromRequest(request);

        Admin admin = adminRepo.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("Admin non trouvé."));

        String newUsername = body.get("username");
        String newEmail = normalizeEmail(body.get("email"));

        if (newUsername == null || newUsername.isBlank()) {
            throw new RuntimeException("Le nom d'utilisateur est obligatoire.");
        }
        if (newEmail == null || !EMAIL_PATTERN.matcher(newEmail).matches()) {
            throw new RuntimeException("Une adresse e-mail valide est obligatoire.");
        }

        newUsername = newUsername.trim();

        boolean usernameTaken = adminRepo.findByUsername(newUsername)
                .filter(other -> !other.getId().equals(admin.getId()))
                .isPresent();

        if (usernameTaken) {
            throw new RuntimeException("Ce nom d'utilisateur est déjà utilisé.");
        }

        boolean emailTaken = adminRepo.findByEmail(newEmail)
                .filter(other -> !other.getId().equals(admin.getId()))
                .isPresent();

        if (emailTaken) {
            throw new RuntimeException("Cette adresse e-mail est déjà utilisée.");
        }

        admin.setUsername(newUsername);
        admin.setEmail(newEmail);
        adminRepo.save(admin);

        return Map.of(
                "message", "Profil mis à jour avec succès.",
                "username", newUsername,
                "email", newEmail,
                "token", jwtUtil.generateToken(newUsername)
        );
    }

    private String getUsernameFromRequest(HttpServletRequest request) {
        String header = request.getHeader("Authorization");

        if (header == null || !header.startsWith("Bearer ")) {
            throw new RuntimeException("Token manquant ou invalide.");
        }

        return jwtUtil.extractUsername(header.substring(7));
    }

    private String normalizeEmail(String email) {
        return email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }

    private void validateAdminFields(String username, String email, String password) {
        if (username == null || username.isBlank()) {
            throw new RuntimeException("Le nom d'utilisateur est obligatoire.");
        }
        if (email == null || !EMAIL_PATTERN.matcher(email).matches()) {
            throw new RuntimeException("Une adresse e-mail valide est obligatoire.");
        }
        if (password == null || password.length() < 8) {
            throw new RuntimeException("Le mot de passe doit contenir au moins 8 caractères.");
        }
    }
}