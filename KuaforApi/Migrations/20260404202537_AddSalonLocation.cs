using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KuaforApi.Migrations
{
    /// <inheritdoc />
    public partial class AddSalonLocation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "Latitude",
                table: "Salons",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Longitude",
                table: "Salons",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "Salons");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "Salons");
        }
    }
}
