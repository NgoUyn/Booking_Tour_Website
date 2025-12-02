namespace Tour_Website.Models
{
    using System;
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using System.Data.Entity.Spatial;

    [Table("Voucher")]
    public partial class Voucher
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Voucher()
        {
            Orders = new HashSet<Order>();
        }

        public int VoucherID { get; set; }

        [StringLength(50)]
        public string Code { get; set; }

        [StringLength(255)]
        public string Description { get; set; }

        public decimal? DiscountPercent { get; set; }

        [StringLength(20)]
        public string ApplicableLevel { get; set; }

        public DateTimeOffset? ExpiryDate { get; set; }

        public bool? IsActive { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<Order> Orders { get; set; }
    }
}
