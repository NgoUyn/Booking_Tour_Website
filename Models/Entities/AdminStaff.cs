namespace Tour_Website.Models.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("AdminStaff")]
    public partial class AdminStaff
    {
        [Key]
        public int AdminID { get; set; }

        [Required]
        [StringLength(150)]
        public string AdminName { get; set; }

        [Required]
        [StringLength(200)]
        public string Email { get; set; }

        [Column(TypeName = "date")]
        public DateTime? BirthDate { get; set; }

        [StringLength(20)]
        public string PhoneNumber { get; set; }

        [StringLength(300)]
        public string AvtUrl { get; set; }

        public int RoleID { get; set; }

        [Required]
        [StringLength(256)]
        public string Password { get; set; }

        public DateTime CreatedAt { get; set; }

        public virtual AdminRole AdminRole { get; set; }
    }
}
