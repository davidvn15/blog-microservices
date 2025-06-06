package com.kalhan.post_service.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateUpdatePostRequest {
        @NotEmpty(message = "Title is mandatory")
        @NotNull(message = "Title is mandatory")
        @Size(max = 12, message = "Title must be less than 100 characters")
        String title;
        String thumbnail;
        @NotEmpty(message = "Content is mandatory")
        @NotNull(message = "Content is mandatory")
        String content;
}
