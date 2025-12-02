using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using Tour_Website.Models;
using Tour_Website.ViewModels;

namespace Tour_Website.DAL
{
    public class UserDAO
    {
        // SỬA LỖI: Đổi từ "TourContext" thành "TourProject_Database1"
        private string connectionString = ConfigurationManager.ConnectionStrings["TourProject_Database1"].ConnectionString;

        // 1. Hàm mã hóa mật khẩu (SHA256)
        public string HashPassword(string password)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                StringBuilder builder = new StringBuilder();
                foreach (byte b in bytes)
                {
                    builder.Append(b.ToString("x2"));
                }
                return builder.ToString();
            }
        }

        // 2. Kiểm tra email đã tồn tại chưa
        public bool CheckEmailExist(string email)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string query = "SELECT COUNT(*) FROM Users WHERE Email = @Email";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@Email", email);
                conn.Open();
                int count = (int)cmd.ExecuteScalar();
                return count > 0;
            }
        }

        // 3. Đăng ký tài khoản mới
        public bool Register(RegisterViewModel model)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string query = @"INSERT INTO Users (UserName, Email, PasswordHash, Role, Status, CreatedAt, IsActive) 
                                 VALUES (@Name, @Email, @Pass, 'Customer', 'Active', GETDATE(), 1)";

                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@Name", model.UserName);
                cmd.Parameters.AddWithValue("@Email", model.Email);
                cmd.Parameters.AddWithValue("@Pass", HashPassword(model.Password));

                conn.Open();
                return cmd.ExecuteNonQuery() > 0;
            }
        }

        // 4. Kiểm tra đăng nhập
        public bool Login(string email, string password)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string query = "SELECT PasswordHash FROM Users WHERE Email = @Email AND IsActive = 1";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@Email", email);

                conn.Open();
                object result = cmd.ExecuteScalar();

                if (result != null)
                {
                    string dbPassHash = result.ToString();
                    return dbPassHash == HashPassword(password);
                }
                return false;
            }
        }

        // 5. Lấy thông tin người dùng
        public User GetUserByEmail(string email)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string query = @"SELECT UserID, UserName, Email, Role, AvatarUrl, Phone, BirthDate, 
                                TotalSpent, MemberLevel, CreatedAt, IsActive, Status 
                                FROM Users WHERE Email = @Email AND IsActive = 1";

                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@Email", email);

                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                {
                    return new User
                    {
                        UserID = (int)reader["UserID"],
                        UserName = reader["UserName"].ToString(),
                        Email = reader["Email"].ToString(),
                        Role = reader["Role"]?.ToString(),
                        AvatarUrl = reader["AvatarUrl"]?.ToString(),
                        Phone = reader["Phone"]?.ToString(),
                        BirthDate = reader["BirthDate"] != DBNull.Value ? (DateTime?)reader["BirthDate"] : null,
                        TotalSpent = reader["TotalSpent"] != DBNull.Value ? (decimal?)reader["TotalSpent"] : null,
                        MemberLevel = reader["MemberLevel"]?.ToString(),
                        CreatedAt = reader["CreatedAt"] != DBNull.Value ? (DateTime?)reader["CreatedAt"] : null,
                        IsActive = reader["IsActive"] != DBNull.Value ? (bool?)reader["IsActive"] : null,
                        Status = reader["Status"]?.ToString()
                    };
                }
                return null;
            }
        }

        // 6. Lấy tên người dùng để hiển thị session
        public string GetUserName(string email)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string query = "SELECT UserName FROM Users WHERE Email = @Email";
                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@Email", email);
                conn.Open();
                return cmd.ExecuteScalar()?.ToString();
            }
        }

        // 7. Cập nhật thông tin user
        public bool UpdateProfile(int userId, string userName, string phone, DateTime? birthDate)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string query = @"UPDATE Users 
                                SET UserName = @UserName, 
                                    Phone = @Phone, 
                                    BirthDate = @BirthDate 
                                WHERE UserID = @UserID";

                SqlCommand cmd = new SqlCommand(query, conn);
                cmd.Parameters.AddWithValue("@UserID", userId);
                cmd.Parameters.AddWithValue("@UserName", userName);
                cmd.Parameters.AddWithValue("@Phone", (object)phone ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@BirthDate", (object)birthDate ?? DBNull.Value);

                conn.Open();
                return cmd.ExecuteNonQuery() > 0;
            }
        }
    }
}