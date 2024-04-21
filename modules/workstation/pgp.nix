{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.modules.workstation.enable {
    age.secrets =
      (
        builtins.mapAttrs
          (name: value: {
            file = ../../secrets + "/${name}.key.age";
            owner = "lennart";
            inherit (config.users.users.lennart) group;
            mode = "0600";
            path = "/home/lennart/.gnupg/private-keys-v1.d/${name}.key";
          })
          {
            "75E3331D14EB3BE00AE4F60B8239E5B969790799" = true;
            "81EDCEC815439600DA23AB15724393D1679C298D" = true;
            "9DF33900CF5820B18A0C66C742A691EAC28D7B14" = true;
            "FDE63AD88CBC90D1ABFB8FDC202C18E088EB7187" = true;
          }
      );

    home-manager.users = {
      lennart = {
        services.gpg-agent = {
          enable = true;
          enableSshSupport = false;
          enableScDaemon = false;
          pinentryPackage = pkgs.pinentry-gnome3;
        };

        programs.gpg = {
          enable = true;
          mutableKeys = true;
          mutableTrust = true;
          publicKeys = [
            {
              # source = pgp_public_key_file;
              text = ''
                -----BEGIN PGP PUBLIC KEY BLOCK-----

                mDMEZiUvQBYJKwYBBAHaRw8BAQdAdA2rrH9qTjLf8gH7jSvHKFc1HmkTuFyeH6c4
                8UVHl720GlplYnJldXMgPHplYnJldXNAemVicmUudXM+iQJ/BBMWCgInAhsBBAsJ
                CAcEFQoJCAUWAgMBAAIeBQIXgAIZARYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJm
                JUdgmhSAAAAAABAAgXByb29mQGFyaWFkbmUuaWRtYXRyaXg6dS96ZWJyZXVzOnpl
                YnJlLnVzP29yZy5rZXlveGlkZS5yPWRCZlFaeENvR1ZtU1R1amZpdjptYXRyaXgu
                b3JnJm9yZy5rZXlveGlkZS5lPWJxS3JjUFZKODF5VFBXWHRhRlhkMmNWTGlXX1Vi
                ZW9QZXlGejZjR1dnVmMzFIAAAAAAEAAacHJvb2ZAYXJpYWRuZS5pZGRuczplaW5o
                b3JuLmpldHp0P3R5cGU9VFhULhSAAAAAABAAFXByb29mQGFyaWFkbmUuaWRkbnM6
                emVicmUudXM/dHlwZT1UWFQyFIAAAAAAEAAZcHJvb2ZAYXJpYWRuZS5pZGh0dHBz
                Oi8va2l0dHkuc29jaWFsL0B6ZWIuFIAAAAAAEAAVcHJvb2ZAYXJpYWRuZS5pZGRu
                czp3aXJzLmluZz90eXBlPVRYVDMUgAAAAAAQABpwcm9vZkBhcmlhZG5lLmlkZG5z
                OmFudGlidWlsZC5pbmc/dHlwZT1UWFRZFIAAAAAAEABAcHJvb2ZAYXJpYWRuZS5p
                ZGh0dHBzOi8vZ2lzdC5naXRodWIuY29tL3plYnJldXMvYTJlYTg3ODJhNGJiYjhj
                MWYzYjEzNjI2NmJmZGJhYzIACgkQEKRswxUtScU09QD/cpEHMfvJZmQnbOPvoL8i
                b3sLMOtYeb4cTfIJ5g0zz7MA/0xwL5qH16fqwI9nM+2NGM9o/724STMCvovQukAA
                sz4GtCNMZW5uYXJ0IEVpY2hob3JuIDxsZW5uYXJ0QHplYnJlLnVzPokCfAQTFgoC
                JAIbAQQLCQgHBBUKCQgFFgIDAQACHgUCF4AWIQQtU8/qGrQBe7Mnr+MQpGzDFS1J
                xQUCZiVHZpoUgAAAAAAQAIFwcm9vZkBhcmlhZG5lLmlkbWF0cml4OnUvemVicmV1
                czp6ZWJyZS51cz9vcmcua2V5b3hpZGUucj1kQmZRWnhDb0dWbVNUdWpmaXY6bWF0
                cml4Lm9yZyZvcmcua2V5b3hpZGUuZT1icUtyY1BWSjgxeVRQV1h0YUZYZDJjVkxp
                V19VYmVvUGV5Rno2Y0dXZ1ZjMxSAAAAAABAAGnByb29mQGFyaWFkbmUuaWRkbnM6
                ZWluaG9ybi5qZXR6dD90eXBlPVRYVC4UgAAAAAAQABVwcm9vZkBhcmlhZG5lLmlk
                ZG5zOnplYnJlLnVzP3R5cGU9VFhUMhSAAAAAABAAGXByb29mQGFyaWFkbmUuaWRo
                dHRwczovL2tpdHR5LnNvY2lhbC9AemViLhSAAAAAABAAFXByb29mQGFyaWFkbmUu
                aWRkbnM6d2lycy5pbmc/dHlwZT1UWFQzFIAAAAAAEAAacHJvb2ZAYXJpYWRuZS5p
                ZGRuczphbnRpYnVpbGQuaW5nP3R5cGU9VFhUWRSAAAAAABAAQHByb29mQGFyaWFk
                bmUuaWRodHRwczovL2dpc3QuZ2l0aHViLmNvbS96ZWJyZXVzL2EyZWE4NzgyYTRi
                YmI4YzFmM2IxMzYyNjZiZmRiYWMyAAoJEBCkbMMVLUnFYwgA/3ruYqjevO1/nYNA
                FTK2fb3ivsDl2gdNQPd8hoidQiYAAP9hSr9OZun3J5FU/m4ICOpjz4zZDKo/snES
                jAJJZ9ikCrQsTGVubmFydCBFaWNoaG9ybiA8bGVubmFydGVpY2hob3JuQGdtYWls
                LmNvbT6JAnwEExYKAiQCGwEECwkIBwQVCgkIBRYCAwEAAh4FAheAFiEELVPP6hq0
                AXuzJ6/jEKRswxUtScUFAmYlR2aaFIAAAAAAEACBcHJvb2ZAYXJpYWRuZS5pZG1h
                dHJpeDp1L3plYnJldXM6emVicmUudXM/b3JnLmtleW94aWRlLnI9ZEJmUVp4Q29H
                Vm1TVHVqZml2Om1hdHJpeC5vcmcmb3JnLmtleW94aWRlLmU9YnFLcmNQVko4MXlU
                UFdYdGFGWGQyY1ZMaVdfVWJlb1BleUZ6NmNHV2dWYzMUgAAAAAAQABpwcm9vZkBh
                cmlhZG5lLmlkZG5zOmVpbmhvcm4uamV0enQ/dHlwZT1UWFQuFIAAAAAAEAAVcHJv
                b2ZAYXJpYWRuZS5pZGRuczp6ZWJyZS51cz90eXBlPVRYVDIUgAAAAAAQABlwcm9v
                ZkBhcmlhZG5lLmlkaHR0cHM6Ly9raXR0eS5zb2NpYWwvQHplYi4UgAAAAAAQABVw
                cm9vZkBhcmlhZG5lLmlkZG5zOndpcnMuaW5nP3R5cGU9VFhUMxSAAAAAABAAGnBy
                b29mQGFyaWFkbmUuaWRkbnM6YW50aWJ1aWxkLmluZz90eXBlPVRYVFkUgAAAAAAQ
                AEBwcm9vZkBhcmlhZG5lLmlkaHR0cHM6Ly9naXN0LmdpdGh1Yi5jb20vemVicmV1
                cy9hMmVhODc4MmE0YmJiOGMxZjNiMTM2MjY2YmZkYmFjMgAKCRAQpGzDFS1JxX5m
                AP0RW+No75FxWjU58xtrFAyLJqA1qmJp3I4LPNEziFzZXgEAkU8Aqsd3L5AGfOJq
                4u//sFujrtuJNp2G+hiLsm2wqQW0MExlbm5hcnQgRWljaGhvcm4gPGxlbm5hcnQu
                ZWljaGhvcm5Ac3R1ZC5oLWRhLmRlPokCfAQTFgoCJAIbAQQLCQgHBBUKCQgFFgID
                AQACHgUCF4AWIQQtU8/qGrQBe7Mnr+MQpGzDFS1JxQUCZiVHZpoUgAAAAAAQAIFw
                cm9vZkBhcmlhZG5lLmlkbWF0cml4OnUvemVicmV1czp6ZWJyZS51cz9vcmcua2V5
                b3hpZGUucj1kQmZRWnhDb0dWbVNUdWpmaXY6bWF0cml4Lm9yZyZvcmcua2V5b3hp
                ZGUuZT1icUtyY1BWSjgxeVRQV1h0YUZYZDJjVkxpV19VYmVvUGV5Rno2Y0dXZ1Zj
                MxSAAAAAABAAGnByb29mQGFyaWFkbmUuaWRkbnM6ZWluaG9ybi5qZXR6dD90eXBl
                PVRYVC4UgAAAAAAQABVwcm9vZkBhcmlhZG5lLmlkZG5zOnplYnJlLnVzP3R5cGU9
                VFhUMhSAAAAAABAAGXByb29mQGFyaWFkbmUuaWRodHRwczovL2tpdHR5LnNvY2lh
                bC9AemViLhSAAAAAABAAFXByb29mQGFyaWFkbmUuaWRkbnM6d2lycy5pbmc/dHlw
                ZT1UWFQzFIAAAAAAEAAacHJvb2ZAYXJpYWRuZS5pZGRuczphbnRpYnVpbGQuaW5n
                P3R5cGU9VFhUWRSAAAAAABAAQHByb29mQGFyaWFkbmUuaWRodHRwczovL2dpc3Qu
                Z2l0aHViLmNvbS96ZWJyZXVzL2EyZWE4NzgyYTRiYmI4YzFmM2IxMzYyNjZiZmRi
                YWMyAAoJEBCkbMMVLUnF6REBAKll4JMYSazYMy5mgpGrKewwj97Pf5q9IWrMAANE
                /e2HAP9Xh9NaNz2k0YEQkuFmkWSjnqDZBvYqjCh8jt6qS1bbBbQoTGVubmFydCBF
                aWNoaG9ybiA8bGVubmFydEBhbnRpYnVpbGQuaW5nPokCfAQTFgoCJAIbAQQLCQgH
                BBUKCQgFFgIDAQACHgUCF4AWIQQtU8/qGrQBe7Mnr+MQpGzDFS1JxQUCZiVHZpoU
                gAAAAAAQAIFwcm9vZkBhcmlhZG5lLmlkbWF0cml4OnUvemVicmV1czp6ZWJyZS51
                cz9vcmcua2V5b3hpZGUucj1kQmZRWnhDb0dWbVNUdWpmaXY6bWF0cml4Lm9yZyZv
                cmcua2V5b3hpZGUuZT1icUtyY1BWSjgxeVRQV1h0YUZYZDJjVkxpV19VYmVvUGV5
                Rno2Y0dXZ1ZjMxSAAAAAABAAGnByb29mQGFyaWFkbmUuaWRkbnM6ZWluaG9ybi5q
                ZXR6dD90eXBlPVRYVC4UgAAAAAAQABVwcm9vZkBhcmlhZG5lLmlkZG5zOnplYnJl
                LnVzP3R5cGU9VFhUMhSAAAAAABAAGXByb29mQGFyaWFkbmUuaWRodHRwczovL2tp
                dHR5LnNvY2lhbC9AemViLhSAAAAAABAAFXByb29mQGFyaWFkbmUuaWRkbnM6d2ly
                cy5pbmc/dHlwZT1UWFQzFIAAAAAAEAAacHJvb2ZAYXJpYWRuZS5pZGRuczphbnRp
                YnVpbGQuaW5nP3R5cGU9VFhUWRSAAAAAABAAQHByb29mQGFyaWFkbmUuaWRodHRw
                czovL2dpc3QuZ2l0aHViLmNvbS96ZWJyZXVzL2EyZWE4NzgyYTRiYmI4YzFmM2Ix
                MzYyNjZiZmRiYWMyAAoJEBCkbMMVLUnFRcUA/jA0dyT2QvO+gdCuhMOXrDoPtgg8
                p7SJBwLraZvzhEUtAQDWpAUFi713Oa1eWpzEIhsi+MERhPqs9ZXAuATYe/jDArQf
                WmVicmV1cyA8emVicmV1c0BhbnRpYnVpbGQuaW5nPokCfAQTFgoCJAIbAQQLCQgH
                BBUKCQgFFgIDAQACHgUCF4AWIQQtU8/qGrQBe7Mnr+MQpGzDFS1JxQUCZiVHZ5oU
                gAAAAAAQAIFwcm9vZkBhcmlhZG5lLmlkbWF0cml4OnUvemVicmV1czp6ZWJyZS51
                cz9vcmcua2V5b3hpZGUucj1kQmZRWnhDb0dWbVNUdWpmaXY6bWF0cml4Lm9yZyZv
                cmcua2V5b3hpZGUuZT1icUtyY1BWSjgxeVRQV1h0YUZYZDJjVkxpV19VYmVvUGV5
                Rno2Y0dXZ1ZjMxSAAAAAABAAGnByb29mQGFyaWFkbmUuaWRkbnM6ZWluaG9ybi5q
                ZXR6dD90eXBlPVRYVC4UgAAAAAAQABVwcm9vZkBhcmlhZG5lLmlkZG5zOnplYnJl
                LnVzP3R5cGU9VFhUMhSAAAAAABAAGXByb29mQGFyaWFkbmUuaWRodHRwczovL2tp
                dHR5LnNvY2lhbC9AemViLhSAAAAAABAAFXByb29mQGFyaWFkbmUuaWRkbnM6d2ly
                cy5pbmc/dHlwZT1UWFQzFIAAAAAAEAAacHJvb2ZAYXJpYWRuZS5pZGRuczphbnRp
                YnVpbGQuaW5nP3R5cGU9VFhUWRSAAAAAABAAQHByb29mQGFyaWFkbmUuaWRodHRw
                czovL2dpc3QuZ2l0aHViLmNvbS96ZWJyZXVzL2EyZWE4NzgyYTRiYmI4YzFmM2Ix
                MzYyNjZiZmRiYWMyAAoJEBCkbMMVLUnFiDsBAKbQYoo5vQhTlDvwDyZ1Ecf8CCLp
                A/dM5STUUU9kkawxAP4hTLo8wIrgz3Ykn/R8utNkmio39vNLgnbPcFxTsHbtA7gz
                BGYlL38WCSsGAQQB2kcPAQEHQEaGVLGBYzQmCwNE2z12mV39/pAGwT7COaY/YIJu
                i5fGiPQEGBYKACYWIQQtU8/qGrQBe7Mnr+MQpGzDFS1JxQUCZiUvfwIbAgUJB4TO
                AACACRAQpGzDFS1JxXUgBBkWCgAdFiEEV32SmEOefdbwi2cyGi8luflnsN4FAmYl
                L38ACgkQGi8luflnsN4UGgEAxCXyS0g/OYFBI0eReVXOPSMcgXQSZWCE60LPOsoZ
                L8YA+LKh4vuVlxiyvgDr+y5bUEU2IHVHBATySb2lSRoETgN4rQD/TPg4fL/8ZlhC
                UMbOmJcuhFzsbLx4l57bEy5GAW6lWM8BAPjxGQ/E/a3h+wD2RIpt3p4krnEZbvNP
                /nMZbWEGMUQMuDMEZiUvhRYJKwYBBAHaRw8BAQdAV4Fw7UJEx1VuefQYGfdvoCXK
                qLtZlQA+pIlWJSdBvzaIfgQYFgoAJhYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJm
                JS+FAhsgBQkHhM4AAAoJEBCkbMMVLUnF8wYA/in86SGCKgb2GSEa1q4Hu7gDP/oT
                W6YG0vWv3mTr/pNuAQCEUl06JwesronEIWv/pjp8agtWpb87SW5dV8oMJDl+Bbg4
                BGYlL4oSCisGAQQBl1UBBQEBB0Cx6NTvPItSIgvlRnBvwVQVP7v7WvY6Dug9e8Yf
                /exPRwMBCAeIfgQYFgoAJhYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJmJS+KAhsM
                BQkHhM4AAAoJEBCkbMMVLUnFTTMBAPTyWbtU2eKx/jew571F+iG5Lo21YDU3txhq
                FH2wnNHDAQD//965FMRLt83bYN7kD2rdkWZu7pSDzLMH1FwO80RnDw==
                =4FdE
                -----END PGP PUBLIC KEY BLOCK-----
              '';
              trust = "ultimate";
            }
          ];
          settings = {
            armor = true;
            keyserver = [ "hkps://keys.openpgp.org" ];
          };
        };
      };
    };
  };
}
