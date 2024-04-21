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
                sz4GiHUEExYKAB0WIQQyHvpSzxVen9ZGJ54PsMoRmF619gUCZiVxtQAKCRAPsMoR
                mF619nO9AQCzbsga5Dsh6AXD+36kXkzL8zA8RkBEPjkdTvJAaip3sQEAjcquj6wX
                BjR9lGGMi3HZ5Dus6pG/pltAadLoYRTDlQu0I0xlbm5hcnQgRWljaGhvcm4gPGxl
                bm5hcnRAemVicmUudXM+iQJ8BBMWCgIkAhsBBAsJCAcEFQoJCAUWAgMBAAIeBQIX
                gBYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJmJUdmmhSAAAAAABAAgXByb29mQGFy
                aWFkbmUuaWRtYXRyaXg6dS96ZWJyZXVzOnplYnJlLnVzP29yZy5rZXlveGlkZS5y
                PWRCZlFaeENvR1ZtU1R1amZpdjptYXRyaXgub3JnJm9yZy5rZXlveGlkZS5lPWJx
                S3JjUFZKODF5VFBXWHRhRlhkMmNWTGlXX1ViZW9QZXlGejZjR1dnVmMzFIAAAAAA
                EAAacHJvb2ZAYXJpYWRuZS5pZGRuczplaW5ob3JuLmpldHp0P3R5cGU9VFhULhSA
                AAAAABAAFXByb29mQGFyaWFkbmUuaWRkbnM6emVicmUudXM/dHlwZT1UWFQyFIAA
                AAAAEAAZcHJvb2ZAYXJpYWRuZS5pZGh0dHBzOi8va2l0dHkuc29jaWFsL0B6ZWIu
                FIAAAAAAEAAVcHJvb2ZAYXJpYWRuZS5pZGRuczp3aXJzLmluZz90eXBlPVRYVDMU
                gAAAAAAQABpwcm9vZkBhcmlhZG5lLmlkZG5zOmFudGlidWlsZC5pbmc/dHlwZT1U
                WFRZFIAAAAAAEABAcHJvb2ZAYXJpYWRuZS5pZGh0dHBzOi8vZ2lzdC5naXRodWIu
                Y29tL3plYnJldXMvYTJlYTg3ODJhNGJiYjhjMWYzYjEzNjI2NmJmZGJhYzIACgkQ
                EKRswxUtScVjCAD/eu5iqN687X+dg0AVMrZ9veK+wOXaB01A93yGiJ1CJgAA/2FK
                v05m6fcnkVT+bggI6mPPjNkMqj+ycRKMAkln2KQKiHUEExYKAB0WIQQyHvpSzxVe
                n9ZGJ54PsMoRmF619gUCZiVxtwAKCRAPsMoRmF619ikIAP4iuaQdCHNoU4HSv8sW
                iRKsx+RLAG6N5H2FzeiNMwVqtQEA1ylVNA32kPAeHuqr8DwevVCaPYXP6XHpmTjL
                idyQzge0LExlbm5hcnQgRWljaGhvcm4gPGxlbm5hcnRlaWNoaG9ybkBnbWFpbC5j
                b20+iQJ8BBMWCgIkAhsBBAsJCAcEFQoJCAUWAgMBAAIeBQIXgBYhBC1Tz+oatAF7
                syev4xCkbMMVLUnFBQJmJUdmmhSAAAAAABAAgXByb29mQGFyaWFkbmUuaWRtYXRy
                aXg6dS96ZWJyZXVzOnplYnJlLnVzP29yZy5rZXlveGlkZS5yPWRCZlFaeENvR1Zt
                U1R1amZpdjptYXRyaXgub3JnJm9yZy5rZXlveGlkZS5lPWJxS3JjUFZKODF5VFBX
                WHRhRlhkMmNWTGlXX1ViZW9QZXlGejZjR1dnVmMzFIAAAAAAEAAacHJvb2ZAYXJp
                YWRuZS5pZGRuczplaW5ob3JuLmpldHp0P3R5cGU9VFhULhSAAAAAABAAFXByb29m
                QGFyaWFkbmUuaWRkbnM6emVicmUudXM/dHlwZT1UWFQyFIAAAAAAEAAZcHJvb2ZA
                YXJpYWRuZS5pZGh0dHBzOi8va2l0dHkuc29jaWFsL0B6ZWIuFIAAAAAAEAAVcHJv
                b2ZAYXJpYWRuZS5pZGRuczp3aXJzLmluZz90eXBlPVRYVDMUgAAAAAAQABpwcm9v
                ZkBhcmlhZG5lLmlkZG5zOmFudGlidWlsZC5pbmc/dHlwZT1UWFRZFIAAAAAAEABA
                cHJvb2ZAYXJpYWRuZS5pZGh0dHBzOi8vZ2lzdC5naXRodWIuY29tL3plYnJldXMv
                YTJlYTg3ODJhNGJiYjhjMWYzYjEzNjI2NmJmZGJhYzIACgkQEKRswxUtScV+ZgD9
                EVvjaO+RcVo1OfMbaxQMiyagNapiadyOCzzRM4hc2V4BAJFPAKrHdy+QBnziauLv
                /7Bbo67biTadhvoYi7JtsKkFiHUEExYKAB0WIQQyHvpSzxVen9ZGJ54PsMoRmF61
                9gUCZiVxuQAKCRAPsMoRmF619mHdAQDAVFU6hkwGafpdok4DHwbFZdL+2tfqnBMK
                ZupUSkYH/wEAv1iT8NoIWFK+jZiT703b8kD2WeGSotZCO+YJjGpZpQS0MExlbm5h
                cnQgRWljaGhvcm4gPGxlbm5hcnQuZWljaGhvcm5Ac3R1ZC5oLWRhLmRlPokCfAQT
                FgoCJAIbAQQLCQgHBBUKCQgFFgIDAQACHgUCF4AWIQQtU8/qGrQBe7Mnr+MQpGzD
                FS1JxQUCZiVHZpoUgAAAAAAQAIFwcm9vZkBhcmlhZG5lLmlkbWF0cml4OnUvemVi
                cmV1czp6ZWJyZS51cz9vcmcua2V5b3hpZGUucj1kQmZRWnhDb0dWbVNUdWpmaXY6
                bWF0cml4Lm9yZyZvcmcua2V5b3hpZGUuZT1icUtyY1BWSjgxeVRQV1h0YUZYZDJj
                VkxpV19VYmVvUGV5Rno2Y0dXZ1ZjMxSAAAAAABAAGnByb29mQGFyaWFkbmUuaWRk
                bnM6ZWluaG9ybi5qZXR6dD90eXBlPVRYVC4UgAAAAAAQABVwcm9vZkBhcmlhZG5l
                LmlkZG5zOnplYnJlLnVzP3R5cGU9VFhUMhSAAAAAABAAGXByb29mQGFyaWFkbmUu
                aWRodHRwczovL2tpdHR5LnNvY2lhbC9AemViLhSAAAAAABAAFXByb29mQGFyaWFk
                bmUuaWRkbnM6d2lycy5pbmc/dHlwZT1UWFQzFIAAAAAAEAAacHJvb2ZAYXJpYWRu
                ZS5pZGRuczphbnRpYnVpbGQuaW5nP3R5cGU9VFhUWRSAAAAAABAAQHByb29mQGFy
                aWFkbmUuaWRodHRwczovL2dpc3QuZ2l0aHViLmNvbS96ZWJyZXVzL2EyZWE4Nzgy
                YTRiYmI4YzFmM2IxMzYyNjZiZmRiYWMyAAoJEBCkbMMVLUnF6REBAKll4JMYSazY
                My5mgpGrKewwj97Pf5q9IWrMAANE/e2HAP9Xh9NaNz2k0YEQkuFmkWSjnqDZBvYq
                jCh8jt6qS1bbBYh1BBMWCgAdFiEEMh76Us8VXp/WRieeD7DKEZhetfYFAmYlcboA
                CgkQD7DKEZhetfa8WgEAuvVYs8Rfj6SOsHqi9KdUi5YinupdHb2R/kxWSpsk7AAB
                APvWorNR4h50UJAdXTErzop9sSgiByCc7Ow+3R2o4GAMtChMZW5uYXJ0IEVpY2ho
                b3JuIDxsZW5uYXJ0QGFudGlidWlsZC5pbmc+iQJ8BBMWCgIkAhsBBAsJCAcEFQoJ
                CAUWAgMBAAIeBQIXgBYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJmJUdmmhSAAAAA
                ABAAgXByb29mQGFyaWFkbmUuaWRtYXRyaXg6dS96ZWJyZXVzOnplYnJlLnVzP29y
                Zy5rZXlveGlkZS5yPWRCZlFaeENvR1ZtU1R1amZpdjptYXRyaXgub3JnJm9yZy5r
                ZXlveGlkZS5lPWJxS3JjUFZKODF5VFBXWHRhRlhkMmNWTGlXX1ViZW9QZXlGejZj
                R1dnVmMzFIAAAAAAEAAacHJvb2ZAYXJpYWRuZS5pZGRuczplaW5ob3JuLmpldHp0
                P3R5cGU9VFhULhSAAAAAABAAFXByb29mQGFyaWFkbmUuaWRkbnM6emVicmUudXM/
                dHlwZT1UWFQyFIAAAAAAEAAZcHJvb2ZAYXJpYWRuZS5pZGh0dHBzOi8va2l0dHku
                c29jaWFsL0B6ZWIuFIAAAAAAEAAVcHJvb2ZAYXJpYWRuZS5pZGRuczp3aXJzLmlu
                Zz90eXBlPVRYVDMUgAAAAAAQABpwcm9vZkBhcmlhZG5lLmlkZG5zOmFudGlidWls
                ZC5pbmc/dHlwZT1UWFRZFIAAAAAAEABAcHJvb2ZAYXJpYWRuZS5pZGh0dHBzOi8v
                Z2lzdC5naXRodWIuY29tL3plYnJldXMvYTJlYTg3ODJhNGJiYjhjMWYzYjEzNjI2
                NmJmZGJhYzIACgkQEKRswxUtScVFxQD+MDR3JPZC876B0K6Ew5esOg+2CDyntIkH
                Autpm/OERS0BANakBQWLvXc5rV5anMQiGyL4wRGE+qz1lcC4BNh7+MMCiHUEExYK
                AB0WIQQyHvpSzxVen9ZGJ54PsMoRmF619gUCZiVxuwAKCRAPsMoRmF619vJKAQCF
                7UXfg7euR50dHX8/e9BQBV3ETDmORYUWLDjZrlfI4QEA9vK8fhw/zavDz/U18QSf
                3olup9/yMQ/RWVJpMz/tnw60H1plYnJldXMgPHplYnJldXNAYW50aWJ1aWxkLmlu
                Zz6JAnwEExYKAiQCGwEECwkIBwQVCgkIBRYCAwEAAh4FAheAFiEELVPP6hq0AXuz
                J6/jEKRswxUtScUFAmYlR2eaFIAAAAAAEACBcHJvb2ZAYXJpYWRuZS5pZG1hdHJp
                eDp1L3plYnJldXM6emVicmUudXM/b3JnLmtleW94aWRlLnI9ZEJmUVp4Q29HVm1T
                VHVqZml2Om1hdHJpeC5vcmcmb3JnLmtleW94aWRlLmU9YnFLcmNQVko4MXlUUFdY
                dGFGWGQyY1ZMaVdfVWJlb1BleUZ6NmNHV2dWYzMUgAAAAAAQABpwcm9vZkBhcmlh
                ZG5lLmlkZG5zOmVpbmhvcm4uamV0enQ/dHlwZT1UWFQuFIAAAAAAEAAVcHJvb2ZA
                YXJpYWRuZS5pZGRuczp6ZWJyZS51cz90eXBlPVRYVDIUgAAAAAAQABlwcm9vZkBh
                cmlhZG5lLmlkaHR0cHM6Ly9raXR0eS5zb2NpYWwvQHplYi4UgAAAAAAQABVwcm9v
                ZkBhcmlhZG5lLmlkZG5zOndpcnMuaW5nP3R5cGU9VFhUMxSAAAAAABAAGnByb29m
                QGFyaWFkbmUuaWRkbnM6YW50aWJ1aWxkLmluZz90eXBlPVRYVFkUgAAAAAAQAEBw
                cm9vZkBhcmlhZG5lLmlkaHR0cHM6Ly9naXN0LmdpdGh1Yi5jb20vemVicmV1cy9h
                MmVhODc4MmE0YmJiOGMxZjNiMTM2MjY2YmZkYmFjMgAKCRAQpGzDFS1JxYg7AQCm
                0GKKOb0IU5Q78A8mdRHH/Agi6QP3TOUk1FFPZJGsMQD+IUy6PMCK4M92JJ/0fLrT
                ZJoqN/bzS4J2z3BcU7B27QOIdQQTFgoAHRYhBDIe+lLPFV6f1kYnng+wyhGYXrX2
                BQJmJXG8AAoJEA+wyhGYXrX2RxsBAOZhH0LGXfssxQe885676oBUus24pimdaxBQ
                EYomSD6JAQC54d7tvEL7Zaxxb4aHDiKe/hpj4hwrPqnJnAAoRaquArgzBGYlL38W
                CSsGAQQB2kcPAQEHQEaGVLGBYzQmCwNE2z12mV39/pAGwT7COaY/YIJui5fGiPQE
                GBYKACYWIQQtU8/qGrQBe7Mnr+MQpGzDFS1JxQUCZiUvfwIbAgUJB4TOAACACRAQ
                pGzDFS1JxXUgBBkWCgAdFiEEV32SmEOefdbwi2cyGi8luflnsN4FAmYlL38ACgkQ
                Gi8luflnsN4UGgEAxCXyS0g/OYFBI0eReVXOPSMcgXQSZWCE60LPOsoZL8YA+LKh
                4vuVlxiyvgDr+y5bUEU2IHVHBATySb2lSRoETgN4rQD/TPg4fL/8ZlhCUMbOmJcu
                hFzsbLx4l57bEy5GAW6lWM8BAPjxGQ/E/a3h+wD2RIpt3p4krnEZbvNP/nMZbWEG
                MUQMuDMEZiUvhRYJKwYBBAHaRw8BAQdAV4Fw7UJEx1VuefQYGfdvoCXKqLtZlQA+
                pIlWJSdBvzaIfgQYFgoAJhYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJmJS+FAhsg
                BQkHhM4AAAoJEBCkbMMVLUnF8wYA/in86SGCKgb2GSEa1q4Hu7gDP/oTW6YG0vWv
                3mTr/pNuAQCEUl06JwesronEIWv/pjp8agtWpb87SW5dV8oMJDl+Bbg4BGYlL4oS
                CisGAQQBl1UBBQEBB0Cx6NTvPItSIgvlRnBvwVQVP7v7WvY6Dug9e8Yf/exPRwMB
                CAeIfgQYFgoAJhYhBC1Tz+oatAF7syev4xCkbMMVLUnFBQJmJS+KAhsMBQkHhM4A
                AAoJEBCkbMMVLUnFTTMBAPTyWbtU2eKx/jew571F+iG5Lo21YDU3txhqFH2wnNHD
                AQD//965FMRLt83bYN7kD2rdkWZu7pSDzLMH1FwO80RnDw==
                =0UzW
                -----END PGP PUBLIC KEY BLOCK-----
              '';
              trust = "ultimate";
            }
          ];
          settings = {
            armor = true;
            ask-cert-level = true;
            keyserver = [ "hkps://keys.openpgp.org" ];
          };
        };
      };
    };
  };
}
