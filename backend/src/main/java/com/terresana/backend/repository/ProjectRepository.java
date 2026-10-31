package com.terresana.backend.repository;

import com.terresana.backend.model.Admin;
import com.terresana.backend.model.Project;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProjectRepository extends JpaRepository<Project, Long> {
    boolean existsByAdmin(Admin admin);
}
