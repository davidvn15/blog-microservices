-- Blog system database schema (PostgreSQL)

-- USERS table to store user accounts
CREATE TABLE users (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       email VARCHAR(255) NOT NULL UNIQUE,
                       password_hash VARCHAR(255) NOT NULL,
                       name VARCHAR(255) NOT NULL,
                       avatar_url TEXT,
                       bio TEXT,
                       role VARCHAR(20) NOT NULL DEFAULT 'user', -- 'user', 'author', 'editor', 'admin'
                       website VARCHAR(255),
                       social_links JSONB, -- Store social media links like Twitter, GitHub, etc.
                       created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                       updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add an index on email for faster lookups
CREATE INDEX idx_users_email ON users(email);

-- CATEGORIES table to store blog categories
CREATE TABLE categories (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            name VARCHAR(100) NOT NULL UNIQUE,
                            slug VARCHAR(100) NOT NULL UNIQUE,
                            description TEXT,
                            parent_id UUID REFERENCES categories(id),
                            created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add an index on slug for faster lookups when filtering by category
CREATE INDEX idx_categories_slug ON categories(slug);

-- POSTS table to store blog posts
CREATE TABLE posts (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       title VARCHAR(255) NOT NULL,
                       slug VARCHAR(255) NOT NULL UNIQUE,
                       excerpt TEXT,
                       content TEXT NOT NULL,
                       featured_image_url TEXT,
                       status VARCHAR(20) NOT NULL DEFAULT 'draft', -- 'draft', 'published', 'archived'
                       author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                       category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
                       published_at TIMESTAMP WITH TIME ZONE,
                       views INTEGER NOT NULL DEFAULT 0,
                       reading_time_minutes INTEGER,
                       is_featured BOOLEAN NOT NULL DEFAULT false,
                       meta_title VARCHAR(255),
                       meta_description TEXT,
                       created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                       updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add indexes to improve query performance
CREATE INDEX idx_posts_author_id ON posts(author_id);
CREATE INDEX idx_posts_category_id ON posts(category_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_slug ON posts(slug);
CREATE INDEX idx_posts_published_at ON posts(published_at);
CREATE INDEX idx_posts_featured ON posts(is_featured) WHERE is_featured = true;

-- TAGS table to store tags for categorizing posts
CREATE TABLE tags (
                      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                      name VARCHAR(100) NOT NULL UNIQUE,
                      slug VARCHAR(100) NOT NULL UNIQUE,
                      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- POST_TAGS junction table for many-to-many relationship between posts and tags
CREATE TABLE post_tags (
                           post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
                           tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
                           PRIMARY KEY (post_id, tag_id)
);

-- Add indexes to optimize joins
CREATE INDEX idx_post_tags_post_id ON post_tags(post_id);
CREATE INDEX idx_post_tags_tag_id ON post_tags(tag_id);

-- COMMENTS table to store post comments
CREATE TABLE comments (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                          parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE, -- For nested comments
                          content TEXT NOT NULL,
                          status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'spam'
                          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                          updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add indexes to improve comment queries
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_comment_id);
CREATE INDEX idx_comments_status ON comments(status);

-- LIKES table to track user likes on posts
CREATE TABLE likes (
                       user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                       post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                       created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                       PRIMARY KEY (user_id, post_id)
);

-- Add indexes to optimize likes queries
CREATE INDEX idx_likes_post_id ON likes(post_id);
CREATE INDEX idx_likes_user_id ON likes(user_id);

-- BOOKMARKS table to track user bookmarks
CREATE TABLE bookmarks (
                           user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                           post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                           created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                           PRIMARY KEY (user_id, post_id)
);

-- Add indexes to optimize bookmark queries
CREATE INDEX idx_bookmarks_post_id ON bookmarks(post_id);
CREATE INDEX idx_bookmarks_user_id ON bookmarks(user_id);

-- SUBSCRIBERS table to track newsletter subscribers
CREATE TABLE subscribers (
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             email VARCHAR(255) NOT NULL UNIQUE,
                             name VARCHAR(255),
                             is_verified BOOLEAN NOT NULL DEFAULT false,
                             verification_token UUID,
                             subscribed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                             unsubscribed_at TIMESTAMP WITH TIME ZONE
);

-- Add an index on email for faster lookups
CREATE INDEX idx_subscribers_email ON subscribers(email);

-- MEDIA table to store uploaded files/images
CREATE TABLE media (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                       filename VARCHAR(255) NOT NULL,
                       original_filename VARCHAR(255) NOT NULL,
                       file_url TEXT NOT NULL,
                       file_type VARCHAR(50) NOT NULL, -- 'image', 'document', 'video', etc.
                       mime_type VARCHAR(100) NOT NULL,
                       file_size INTEGER NOT NULL, -- size in bytes
                       dimensions JSONB, -- for images: {width: X, height: Y}
                       alt_text TEXT,
                       caption TEXT,
                       uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add indexes to optimize media queries
CREATE INDEX idx_media_user_id ON media(user_id);
CREATE INDEX idx_media_file_type ON media(file_type);

-- POST_VIEWS table to track detailed post view analytics
CREATE TABLE post_views (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                            user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- nullable for anonymous users
                            ip_address VARCHAR(45), -- Can store IPv6 addresses
                            user_agent TEXT,
                            referer TEXT,
                            viewed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add indexes to optimize view analytics queries
CREATE INDEX idx_post_views_post_id ON post_views(post_id);
CREATE INDEX idx_post_views_user_id ON post_views(user_id);
CREATE INDEX idx_post_views_viewed_at ON post_views(viewed_at);

-- SESSIONS table to track user sessions
CREATE TABLE sessions (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                          token VARCHAR(255) NOT NULL UNIQUE,
                          user_agent TEXT,
                          ip_address VARCHAR(45),
                          expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
                          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                          last_active_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Add indexes to optimize session lookups
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);

-- Create functions to automatically update timestamps
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to update timestamps on row updates
CREATE TRIGGER update_users_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_posts_timestamp
    BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_categories_timestamp
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_comments_timestamp
    BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();