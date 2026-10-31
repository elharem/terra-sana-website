package com.terresana.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import java.util.List;

@Entity
@Data
@Table(name = "admin",
        uniqueConstraints = {
                @UniqueConstraint(name = "uq_admin_username", columnNames = "username"),
                @UniqueConstraint(name = "uq_admin_email", columnNames = "email")
        })
public class Admin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String username;

    @Column
    private String email;

    // Un compte désactivé ne peut plus obtenir de rôle ADMIN depuis son ancien JWT.
    @Column(nullable = false, columnDefinition = "boolean default true")
    private boolean active = true;

    // Le hash ne doit jamais être renvoyé dans une réponse JSON.
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(nullable = false)
    private String password;

    // Ces associations évitent les boucles de sérialisation Admin ↔ contenu.
    // La suppression d'un admin lié à du contenu est bloquée par le contrôleur.
    @JsonIgnore
    @OneToMany(mappedBy = "admin", cascade = CascadeType.ALL)
    private List<Project> projects;

    @JsonIgnore
    @OneToMany(mappedBy = "admin", cascade = CascadeType.ALL)
    private List<BlogPost> blogPosts;

    @JsonIgnore
    @OneToMany(mappedBy = "admin", cascade = CascadeType.ALL)
    private List<ContactMessage> messages;
}
