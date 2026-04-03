using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KuaforApi.Migrations
{
    /// <inheritdoc />
    public partial class AddStylistIdToService : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Services_Salons_SalonId",
                table: "Services");

            migrationBuilder.AlterColumn<int>(
                name: "SalonId",
                table: "Services",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddColumn<int>(
                name: "StylistId",
                table: "Services",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Services_StylistId",
                table: "Services",
                column: "StylistId");

            migrationBuilder.AddForeignKey(
                name: "FK_Services_Salons_SalonId",
                table: "Services",
                column: "SalonId",
                principalTable: "Salons",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Services_Users_StylistId",
                table: "Services",
                column: "StylistId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Services_Salons_SalonId",
                table: "Services");

            migrationBuilder.DropForeignKey(
                name: "FK_Services_Users_StylistId",
                table: "Services");

            migrationBuilder.DropIndex(
                name: "IX_Services_StylistId",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "StylistId",
                table: "Services");

            migrationBuilder.AlterColumn<int>(
                name: "SalonId",
                table: "Services",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Services_Salons_SalonId",
                table: "Services",
                column: "SalonId",
                principalTable: "Salons",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
