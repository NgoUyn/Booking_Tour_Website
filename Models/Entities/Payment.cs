namespace Tour_Website.Models.Entities
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Payment")]
    public partial class Payment
    {
        public int PaymentID { get; set; }

        public int? OrderID { get; set; }

        public decimal? Amount { get; set; }

        [StringLength(50)]
        public string PaymentMethod { get; set; }

        public DateTimeOffset? PaymentDate { get; set; }

        [StringLength(20)]
        public string Status { get; set; }

        [StringLength(100)]
        public string TransactionCode { get; set; }

        public virtual Order Order { get; set; }
    }
}
