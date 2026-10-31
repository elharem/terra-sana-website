package com.terresana.backend.repository;

import com.terresana.backend.model.Admin;
import com.terresana.backend.model.BlogPost;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BlogPostRepository extends JpaRepository<BlogPost, Long> {
    List<BlogPost> findAllByOrderByCreatedAtDesc();
    boolean existsByAdmin(Admin admin);
}