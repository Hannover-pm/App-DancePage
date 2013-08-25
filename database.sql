SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,PAD_CHAR_TO_FULL_LENGTH';

DROP SCHEMA IF EXISTS `dancepage` ;
CREATE SCHEMA IF NOT EXISTS `dancepage` DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ;
USE `dancepage` ;

-- -----------------------------------------------------
-- Table `dancepage`.`Users`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Users` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Users` (
  `user_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `username` VARCHAR(255) NOT NULL ,
  `email` VARCHAR(254) NOT NULL ,
  `password` VARCHAR(255) NOT NULL ,
  `signup_on` DATETIME NOT NULL ,
  `last_login_on` DATETIME NULL DEFAULT NULL ,
  `has_failed_logins` TINYINT UNSIGNED NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`user_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE UNIQUE INDEX `Users_username` ON `dancepage`.`Users` (`username` ASC) ;

CREATE UNIQUE INDEX `Users_email` ON `dancepage`.`Users` (`email` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`Roles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Roles` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Roles` (
  `role_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `role` VARCHAR(255) NOT NULL ,
  PRIMARY KEY (`role_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE UNIQUE INDEX `Roles_role` ON `dancepage`.`Roles` (`role` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`User_Roles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`User_Roles` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`User_Roles` (
  `user_id` INT UNSIGNED NOT NULL ,
  `role_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`user_id`, `role_id`) ,
  CONSTRAINT `Role_Users`
    FOREIGN KEY (`user_id` )
    REFERENCES `dancepage`.`Users` (`user_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `User_Roles`
    FOREIGN KEY (`role_id` )
    REFERENCES `dancepage`.`Roles` (`role_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE INDEX `User_Roles_role_id` ON `dancepage`.`User_Roles` (`role_id` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`Page_Categories`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Page_Categories` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Page_Categories` (
  `category_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `category` VARCHAR(255) NOT NULL ,
  `abstract` VARCHAR(150) NOT NULL ,
  `category_uri` VARCHAR(255) NOT NULL ,
  PRIMARY KEY (`category_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE UNIQUE INDEX `Page_Categories_category` ON `dancepage`.`Page_Categories` (`category` ASC) ;

CREATE UNIQUE INDEX `Page_Categories_category_uri` ON `dancepage`.`Page_Categories` (`category_uri` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`Pages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Pages` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Pages` (
  `page_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `category_id` INT UNSIGNED NOT NULL ,
  `user_id` INT UNSIGNED NOT NULL ,
  `subject` VARCHAR(80) NOT NULL ,
  `abstract` VARCHAR(150) NOT NULL ,
  `message` MEDIUMTEXT NOT NULL ,
  `publication_on` DATETIME NULL DEFAULT NULL ,
  `has_edits` TINYINT UNSIGNED NOT NULL DEFAULT 0 ,
  `last_edit_on` DATETIME NULL DEFAULT NULL ,
  `has_views` INT UNSIGNED NOT NULL DEFAULT 0 ,
  `page_uri` VARCHAR(255) NOT NULL ,
  PRIMARY KEY (`page_id`) ,
  CONSTRAINT `Page_Category`
    FOREIGN KEY (`category_id` )
    REFERENCES `dancepage`.`Page_Categories` (`category_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `Page_Author`
    FOREIGN KEY (`user_id` )
    REFERENCES `dancepage`.`Users` (`user_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE UNIQUE INDEX `Pages_uri` ON `dancepage`.`Pages` (`page_uri` ASC, `category_id` ASC) ;

CREATE INDEX `Pages_category_id` ON `dancepage`.`Pages` (`category_id` ASC) ;

CREATE INDEX `Pages_user_id` ON `dancepage`.`Pages` (`user_id` ASC) ;

CREATE INDEX `Pages_has_views` ON `dancepage`.`Pages` (`has_views` ASC) ;

CREATE INDEX `Pages_publication_on` ON `dancepage`.`Pages` (`publication_on` ASC) ;

CREATE INDEX `Pages_last_edit_on` ON `dancepage`.`Pages` (`last_edit_on` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`Comments`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Comments` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Comments` (
  `comment_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `page_id` INT UNSIGNED NOT NULL ,
  `user_id` INT UNSIGNED NULL DEFAULT NULL ,
  `displayname` VARCHAR(255) NOT NULL ,
  `commented_on` DATETIME NOT NULL ,
  `message` TEXT NOT NULL ,
  PRIMARY KEY (`comment_id`) ,
  CONSTRAINT `User_Comments`
    FOREIGN KEY (`user_id` )
    REFERENCES `dancepage`.`Users` (`user_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `Page_Comments`
    FOREIGN KEY (`page_id` )
    REFERENCES `dancepage`.`Pages` (`page_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE INDEX `Comments_user_id` ON `dancepage`.`Comments` (`user_id` ASC) ;

CREATE INDEX `Comments_page_id` ON `dancepage`.`Comments` (`page_id` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`Tags`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Tags` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Tags` (
  `tag_id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `tag` VARCHAR(25) NOT NULL ,
  `tag_uri` VARCHAR(255) NOT NULL ,
  `has_entries` INT UNSIGNED NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`tag_id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE UNIQUE INDEX `Tags_tag` ON `dancepage`.`Tags` (`tag` ASC) ;

CREATE UNIQUE INDEX `Tags_tag_uri` ON `dancepage`.`Tags` (`tag_uri` ASC) ;

CREATE INDEX `Tags_has_entries` ON `dancepage`.`Tags` (`has_entries` ASC) ;


-- -----------------------------------------------------
-- Table `dancepage`.`Page_Tags`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `dancepage`.`Page_Tags` ;

CREATE  TABLE IF NOT EXISTS `dancepage`.`Page_Tags` (
  `page_id` INT UNSIGNED NOT NULL ,
  `tag_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`page_id`, `tag_id`) ,
  CONSTRAINT `Page_Tags`
    FOREIGN KEY (`page_id` )
    REFERENCES `dancepage`.`Pages` (`page_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `Tag_Pages`
    FOREIGN KEY (`tag_id` )
    REFERENCES `dancepage`.`Tags` (`tag_id` )
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_unicode_ci;

CREATE INDEX `Page_Tags_tag_id` ON `dancepage`.`Page_Tags` (`tag_id` ASC) ;

USE `dancepage` ;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Users`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Users` (`user_id`, `username`, `email`, `password`, `signup_on`, `last_login_on`, `has_failed_logins`) VALUES (1, 'root', 'root@localhost', '!', '1970-01-01 01:00:00', NULL, 0);

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Roles`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Roles` (`role_id`, `role`) VALUES (1, 'admin');
INSERT INTO `dancepage`.`Roles` (`role_id`, `role`) VALUES (2, 'pages_create');
INSERT INTO `dancepage`.`Roles` (`role_id`, `role`) VALUES (3, 'pages_edit');
INSERT INTO `dancepage`.`Roles` (`role_id`, `role`) VALUES (4, 'pages_publish');
INSERT INTO `dancepage`.`Roles` (`role_id`, `role`) VALUES (5, 'pages_delete');
INSERT INTO `dancepage`.`Roles` (`role_id`, `role`) VALUES (6, 'pages_comment');

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`User_Roles`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`User_Roles` (`user_id`, `role_id`) VALUES (1, 1);

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Page_Categories`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Page_Categories` (`category_id`, `category`, `abstract`, `category_uri`) VALUES (1, 'Special Pages', 'This category belongs to special pages which are out of the regular categories.', '');
INSERT INTO `dancepage`.`Page_Categories` (`category_id`, `category`, `abstract`, `category_uri`) VALUES (2, 'Blog', 'My web diary.', 'blog');

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Pages`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Pages` (`page_id`, `category_id`, `user_id`, `subject`, `abstract`, `message`, `publication_on`, `has_edits`, `last_edit_on`, `has_views`, `page_uri`) VALUES (1, 1, 1, 'About me', 'Some information about myself.', '*TODO:* _Enter content here_', '1970-01-01 01:00:00', 0, NULL, 0, 'about-me');
INSERT INTO `dancepage`.`Pages` (`page_id`, `category_id`, `user_id`, `subject`, `abstract`, `message`, `publication_on`, `has_edits`, `last_edit_on`, `has_views`, `page_uri`) VALUES (2, 2, 1, 'Hello world', 'This is my first blog post.', '*Hello, world!* _This is my first blog post._', '1970-01-01 01:00:00', 0, NULL, 0, 'hello-world');

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Comments`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Comments` (`comment_id`, `page_id`, `user_id`, `displayname`, `commented_on`, `message`) VALUES (1, 2, 1, 'root', '1970-01-01 01:00:00', 'Yo! \'Sup :)');

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Tags`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Tags` (`tag_id`, `tag`, `tag_uri`, `has_entries`) VALUES (1, 'Hello World', 'hello-world', 1);

COMMIT;

-- -----------------------------------------------------
-- Data for table `dancepage`.`Page_Tags`
-- -----------------------------------------------------
START TRANSACTION;
USE `dancepage`;
INSERT INTO `dancepage`.`Page_Tags` (`page_id`, `tag_id`) VALUES (1, 1);

COMMIT;
