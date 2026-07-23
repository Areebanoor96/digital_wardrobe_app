import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class FamilyMemberCard extends ConsumerWidget {

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onTap,
    this.onDelete,
  });


  final FamilyMember member;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;


  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Card(

      child: ListTile(

        onTap: onTap,


        leading: CircleAvatar(
          child: Text(
            member.name.characters.first.toUpperCase(),
          ),
        ),


        title: Text(member.name),


        subtitle: Text(
          member.relationship.label,
        ),


        trailing: PopupMenuButton<String>(

          onSelected: (value){

            if(value == "select"){

              ref
                  .read(selectedFamilyMemberProvider.notifier)
                  .state = member;


              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    "${member.name}'s wardrobe selected",
                  ),
                ),
              );

            }


            if(value == "delete"){
              onDelete?.call();
            }

          },


          itemBuilder: (context)=>[


            const PopupMenuItem(

              value:"select",

              child: Row(
                children:[

                  Icon(Icons.checkroom),

                  SizedBox(width:8),

                  Text("Use wardrobe"),

                ],
              ),
            ),



            const PopupMenuItem(

              value:"delete",

              child: Row(
                children:[

                  Icon(Icons.delete),

                  SizedBox(width:8),

                  Text("Delete"),

                ],
              ),
            ),


          ],

        ),

      ),

    );

  }

}