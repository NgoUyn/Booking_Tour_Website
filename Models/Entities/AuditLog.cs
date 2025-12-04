namespace Tour_Website.Models.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("AuditLog")]
    public partial class AuditLog
    {
        [Key]
        public int LogID { get; set; }

        [StringLength(100)]
        public string TableName { get; set; }

        [StringLength(10)]
        public string Action { get; set; }

        [StringLength(255)]
        public string AdminName { get; set; }

        public DateTime? TimeStamp { get; set; }

        public string Detail { get; set; }
    }
}
